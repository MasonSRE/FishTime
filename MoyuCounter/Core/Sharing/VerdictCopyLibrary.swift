import Foundation

enum VerdictCopyLibrary {
    static func copies(for label: DailyScoreLabel) -> [String] {
        switch label {
        case .topNiuMa:
            return [
                AppStrings.Score.topNiuMaOneLiner,
                "工位今天像点了涡轮，连空气都在加班。",
                "你今天不是在敲键盘，是在给桌面打铁。",
            ]
        case .balancedHuman:
            return [
                AppStrings.Score.balancedHumanOneLiner,
                "今天的你会工作，也会给自己留口气。",
                "进可输出，退可潜航，节奏拿得很稳。",
            ]
        case .moyuMaster:
            return [
                AppStrings.Score.moyuMasterOneLiner,
                "今天的主要 KPI，是不惊动任何人地活着。",
                "你和工位保持了体面的表面关系。",
            ]
        }
    }
}
