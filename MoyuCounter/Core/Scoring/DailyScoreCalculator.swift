import Foundation

struct MinuteActivitySample {
    let epm: Int
    let minutes: Int
}

final class DailyScoreCalculator {
    private let thresholds: ScoringThresholds

    init(thresholds: ScoringThresholds = .default) {
        self.thresholds = thresholds
    }

    func calculate(from samples: [MinuteActivitySample]) -> DailyScoreResult {
        let trackedMinutes = max(samples.reduce(0) { $0 + $1.minutes }, 1)

        let lowMinutes = samples.reduce(0) { partial, sample in
            partial + (sample.epm < thresholds.lowActivityEPM ? sample.minutes : 0)
        }
        let highMinutes = samples.reduce(0) { partial, sample in
            partial + (sample.epm >= thresholds.highActivityEPM ? sample.minutes : 0)
        }

        let lowRatio = Double(lowMinutes) / Double(trackedMinutes)
        let highRatio = Double(highMinutes) / Double(trackedMinutes)

        let longestIdleMinutes = longestIdleRun(in: samples)
        let idleRatio = Double(longestIdleMinutes) / Double(trackedMinutes)

        let raw = 100 * (0.55 * highRatio + 0.25 * (1 - lowRatio) + 0.20 * (1 - idleRatio))
        let laborScore = min(100, max(0, Int(raw.rounded())))
        let moyuScore = 100 - laborScore

        let label: DailyScoreLabel
        let oneLiner: String
        switch laborScore {
        case 75...100:
            label = .topNiuMa
            oneLiner = AppStrings.Score.topNiuMaOneLiner
        case 45..<75:
            label = .balancedHuman
            oneLiner = AppStrings.Score.balancedHumanOneLiner
        default:
            label = .moyuMaster
            oneLiner = AppStrings.Score.moyuMasterOneLiner
        }

        return DailyScoreResult(
            laborScore: laborScore,
            moyuScore: moyuScore,
            label: label,
            oneLiner: oneLiner,
            trackedMinutes: trackedMinutes,
            lowActivityMinutes: lowMinutes,
            highActivityMinutes: highMinutes,
            longestIdleMinutes: longestIdleMinutes
        )
    }

    private func longestIdleRun(in samples: [MinuteActivitySample]) -> Int {
        var longestRun = 0
        var currentRun = 0

        for sample in samples {
            if sample.epm < thresholds.lowActivityEPM {
                currentRun += sample.minutes
                longestRun = max(longestRun, currentRun)
            } else {
                currentRun = 0
            }
        }

        return longestRun
    }
}
