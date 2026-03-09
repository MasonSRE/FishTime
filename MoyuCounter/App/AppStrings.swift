import Foundation

enum AppStrings {
    enum App {
        static let name = "摸鱼统计器"
    }

    enum Window {
        static let main = "摸鱼统计器"
        static let history = "历史记录"
    }

    enum MenuBar {
        static let statusLabel = "状态"
        static let todayEventsLabel = "今日事件数"
        static let startTracking = "开始统计"
        static let stopTracking = "停止统计"
        static let generatePoster = "生成今日海报"
        static let copyPoster = "复制海报到剪贴板"
        static let openHistory = "打开历史记录"
        static let openSettings = "打开设置"
    }

    enum Permission {
        static let grantPermission = "授权权限"
        static let granted = "权限已授权，可开始统计。"
        static let required = "需要输入监听权限才能开始统计。"
        static let requested = "已发起权限请求，请在系统设置中同意后重新打开应用。"
        static let denied = "权限被拒绝，请在系统设置中开启辅助功能权限。"
    }

    enum Settings {
        static let trackingScope = "统计范围"
        static let workHoursOnly = "仅工作时段"
        static let wholeDay = "全天"
        static let startMinute = "开始分钟"
        static let endMinute = "结束分钟"
        static let resetLocalData = "重置本地数据"
    }

    enum RuntimeStatus {
        static let notStarted = "未开始"
        static let tracking = "统计中"
        static let settledPrefix = "已结算"
        static let settlementFailed = "结算失败"
        static let posterUnavailable = "海报功能不可用"
        static let posterSavedPrefix = "海报已保存"
        static let posterSaveFailed = "保存海报失败"
        static let posterCopied = "战报图文已复制"
        static let posterCopyFailed = "复制海报失败"
    }

    enum Score {
        static let topNiuMaTitle = "顶级牛马"
        static let balancedHumanTitle = "平衡人类"
        static let moyuMasterTitle = "摸鱼大师"
        static let topNiuMaOneLiner = "键盘冒火星，鼠标擦出电。"
        static let balancedHumanOneLiner = "工作与摸鱼，正在动态平衡。"
        static let moyuMasterOneLiner = "你的鱼跑出去，又带着朋友回来了。"
    }

    enum Notification {
        static let settledTitlePrefix = "今日已结算"
        static let openReportPrompt = "打开应用可复制今日战报"
    }

    enum Poster {
        static let laborScorePrefix = "劳动分"
    }

    enum Report {
        static let sectionTitle = "今日战报"
        static let templateSectionTitle = "分享模板"
        static let templatePickerHint = "切换模板会立即刷新预览，并用于复制与保存。"
        static let emptyTitle = "今日战报待生成"
        static let emptySubtitle = "完成日结后，这里会展示称号、毒舌判词和今日亮点。"
        static let standardTemplate = "标准战报"
        static let certificateTemplate = "奖状"
        static let deskLogTemplate = "工位日报"
        static let refreshVerdict = "刷新判词"
        static let copyReport = "复制今日战报"
        static let saveReport = "保存战报图片"
    }
}
