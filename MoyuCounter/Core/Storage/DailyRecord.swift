import Foundation

struct DailyRecord: Codable, Equatable {
    let date: Date
    let score: Int
    let moyuScore: Int
    let label: String
    let activeMinutes: Int
    let trackedMinutes: Int
    let highActivityMinutes: Int
    let lowActivityMinutes: Int
    let longestIdleMinutes: Int

    init(
        date: Date,
        score: Int,
        moyuScore: Int? = nil,
        label: String,
        activeMinutes: Int,
        trackedMinutes: Int? = nil,
        highActivityMinutes: Int = 0,
        lowActivityMinutes: Int = 0,
        longestIdleMinutes: Int = 0
    ) {
        self.date = date
        self.score = score
        self.moyuScore = moyuScore ?? max(0, 100 - score)
        self.label = label
        self.activeMinutes = activeMinutes
        self.trackedMinutes = max(trackedMinutes ?? activeMinutes, 1)
        self.highActivityMinutes = highActivityMinutes
        self.lowActivityMinutes = lowActivityMinutes
        self.longestIdleMinutes = longestIdleMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case score
        case moyuScore
        case label
        case activeMinutes
        case trackedMinutes
        case highActivityMinutes
        case lowActivityMinutes
        case longestIdleMinutes
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let date = try container.decode(Date.self, forKey: .date)
        let score = try container.decode(Int.self, forKey: .score)
        let label = try container.decode(String.self, forKey: .label)
        let activeMinutes = try container.decode(Int.self, forKey: .activeMinutes)

        self.init(
            date: date,
            score: score,
            moyuScore: try container.decodeIfPresent(Int.self, forKey: .moyuScore),
            label: label,
            activeMinutes: activeMinutes,
            trackedMinutes: try container.decodeIfPresent(Int.self, forKey: .trackedMinutes),
            highActivityMinutes: try container.decodeIfPresent(Int.self, forKey: .highActivityMinutes) ?? 0,
            lowActivityMinutes: try container.decodeIfPresent(Int.self, forKey: .lowActivityMinutes) ?? 0,
            longestIdleMinutes: try container.decodeIfPresent(Int.self, forKey: .longestIdleMinutes) ?? 0
        )
    }
}
