import Foundation

enum QuickSelectOption: String, CaseIterable, Identifiable {
    case today
    case thisWeek
    case thisMonth
    case nextMonth
    case next7
    case next14
    case next30
    case thisQuarter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .today: return "今天"
        case .thisWeek: return "本周"
        case .thisMonth: return "本月"
        case .nextMonth: return "下月"
        case .next7: return "未来 7 天"
        case .next14: return "未来 14 天"
        case .next30: return "未来 30 天"
        case .thisQuarter: return "本季度"
        }
    }
}
