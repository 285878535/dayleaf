import Foundation

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case fresh
    case cute
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fresh: return "绿色清新"
        case .cute: return "粉色可爱"
        case .system: return "跟随系统"
        }
    }
}

enum ViewMode: String, Codable, CaseIterable, Identifiable {
    case single
    case double
    case triple

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: return "单月视图"
        case .double: return "双月视图"
        case .triple: return "三月视图"
        }
    }

    var monthCount: Int {
        switch self {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }
}

enum LunarDisplayMode: String, Codable, CaseIterable, Identifiable {
    case off
    case simple
    case full

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "关闭"
        case .simple: return "简洁"
        case .full: return "完整"
        }
    }
}

enum WeekStartDay: String, Codable, CaseIterable, Identifiable {
    case monday
    case sunday

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monday: return "周一"
        case .sunday: return "周日"
        }
    }

    /// Calendar.firstWeekday: 1 = Sunday ... 7 = Saturday
    var firstWeekdayIndex: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        }
    }
}

enum WorkRuleType: String, Codable, CaseIterable, Identifiable {
    case doubleRest
    case singleRest
    case bigSmallWeek
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .doubleRest: return "双休"
        case .singleRest: return "单休"
        case .bigSmallWeek: return "大小周"
        case .custom: return "自定义"
        }
    }
}

enum DateFormatOption: String, Codable, CaseIterable, Identifiable {
    case dotted
    case slashed
    case chinese

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dotted: return "yyyy.MM.dd"
        case .slashed: return "yyyy/MM/dd"
        case .chinese: return "yyyy年M月d日"
        }
    }

    var dateFormat: String {
        switch self {
        case .dotted: return "yyyy.MM.dd"
        case .slashed: return "yyyy/MM/dd"
        case .chinese: return "yyyy年M月d日"
        }
    }
}

enum StatusBarIconOption: String, Codable, CaseIterable, Identifiable {
    case calendar
    case leaf
    case paw

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calendar: return "日历"
        case .leaf: return "叶子"
        case .paw: return "猫爪"
        }
    }

    var symbolName: String {
        switch self {
        case .calendar: return "calendar"
        case .leaf: return "leaf.fill"
        case .paw: return "pawprint.fill"
        }
    }
}

enum CopyTemplateType: String, Codable, CaseIterable, Identifiable {
    case simple
    case work
    case leave
    case project
    case markdown
    case json
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simple: return "简洁版"
        case .work: return "工作版"
        case .leave: return "请假版"
        case .project: return "项目排期版"
        case .markdown: return "Markdown 表格"
        case .json: return "JSON"
        case .custom: return "自定义模板"
        }
    }
}
