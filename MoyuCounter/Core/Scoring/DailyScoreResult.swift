enum DailyScoreLabel: String {
    case topNiuMa
    case balancedHuman
    case moyuMaster

    init(storedValue: String) {
        self = DailyScoreLabel(rawValue: storedValue) ?? .balancedHuman
    }

    var defaultOneLiner: String {
        switch self {
        case .topNiuMa:
            return AppStrings.Score.topNiuMaOneLiner
        case .balancedHuman:
            return AppStrings.Score.balancedHumanOneLiner
        case .moyuMaster:
            return AppStrings.Score.moyuMasterOneLiner
        }
    }
}

struct DailyScoreResult {
    let laborScore: Int
    let moyuScore: Int
    let label: DailyScoreLabel
    let oneLiner: String
    let trackedMinutes: Int
    let lowActivityMinutes: Int
    let highActivityMinutes: Int
    let longestIdleMinutes: Int
}
