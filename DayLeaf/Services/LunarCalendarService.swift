import Foundation

/// Converts Gregorian dates to lunar (农历) display text, and looks up traditional
/// festivals and solar terms. Solar term dates are an approximation table (accurate
/// to within a day for most years) since exact astronomical calculation is out of
/// scope for this lightweight tool.
final class LunarCalendarService {
    static let shared = LunarCalendarService()

    private let chineseCalendar: Calendar = {
        var cal = Calendar(identifier: .chinese)
        cal.timeZone = TimeZone.current
        return cal
    }()

    private let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        return f
    }()

    /// 农历转换会经由 ICU 计算,开销明显高于公历运算。按天缓存结果，
    /// 避免拖拽选择时因高频重绘而反复触发昂贵的农历换算导致界面卡顿。
    private var lunarCache: [String: LunarInfo?] = [:]

    private static let dayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    private static let monthNames = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月"
    ]

    /// 农历传统节日,按(月,日)匹配
    private static let lunarFestivals: [String: String] = [
        "1-1": "春节",
        "1-15": "元宵节",
        "5-5": "端午节",
        "7-7": "七夕",
        "7-15": "中元节",
        "8-15": "中秋节",
        "9-9": "重阳节",
        "12-8": "腊八节"
    ]

    /// 固定公历节日,按(月,日)匹配
    private static let solarFestivals: [String: String] = [
        "1-1": "元旦",
        "2-14": "情人节",
        "3-8": "妇女节",
        "3-12": "植树节",
        "4-1": "愚人节",
        "5-1": "劳动节",
        "5-4": "青年节",
        "6-1": "儿童节",
        "7-1": "建党节",
        "8-1": "建军节",
        "9-10": "教师节",
        "10-1": "国庆节",
        "12-25": "圣诞节"
    ]

    /// 24节气近似公历日期(月,日) -> 名称,存在±1天误差
    private static let solarTerms: [String: String] = [
        "1-5": "小寒", "1-20": "大寒",
        "2-4": "立春", "2-19": "雨水",
        "3-5": "惊蛰", "3-20": "春分",
        "4-5": "清明", "4-20": "谷雨",
        "5-5": "立夏", "5-21": "小满",
        "6-5": "芒种", "6-21": "夏至",
        "7-7": "小暑", "7-22": "大暑",
        "8-7": "立秋", "8-23": "处暑",
        "9-7": "白露", "9-23": "秋分",
        "10-8": "寒露", "10-23": "霜降",
        "11-7": "立冬", "11-22": "小雪",
        "12-7": "大雪", "12-22": "冬至"
    ]

    struct LunarInfo {
        let day: Int
        let dayText: String
        let isFirstDayOfMonth: Bool
        let lunarFestival: String?
    }

    func lunarInfo(for date: Date) -> LunarInfo? {
        let key = dayKeyFormatter.string(from: date)
        if let cached = lunarCache[key] {
            return cached
        }
        let info = computeLunarInfo(for: date)
        lunarCache[key] = info
        return info
    }

    private func computeLunarInfo(for date: Date) -> LunarInfo? {
        let components = chineseCalendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day,
              month >= 1, month <= 12, day >= 1, day <= Self.dayNames.count else {
            return nil
        }
        let monthName = Self.monthNames[month - 1]
        let isFirstDay = day == 1
        let dayText = isFirstDay ? monthName + Self.dayNames[0] : Self.dayNames[day - 1]
        let festival = Self.lunarFestivals["\(month)-\(day)"]
        return LunarInfo(day: day, dayText: dayText, isFirstDayOfMonth: isFirstDay, lunarFestival: festival)
    }

    func solarFestival(for date: Date) -> String? {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day else { return nil }
        return Self.solarFestivals["\(month)-\(day)"]
    }

    func solarTerm(for date: Date) -> String? {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day else { return nil }
        return Self.solarTerms["\(month)-\(day)"]
    }

    /// 农历文案优先级: 法定节假日名称 > 传统节日 > 节气 > 公历节日 > 农历日期
    func displayText(for date: Date, holidayName: String?, mode: LunarDisplayMode) -> String? {
        guard mode != .off else { return nil }

        if let holidayName, !holidayName.isEmpty {
            return holidayName
        }
        let lunar = lunarInfo(for: date)
        if let festival = lunar?.lunarFestival {
            return festival
        }
        if let term = solarTerm(for: date) {
            return term
        }
        if let solar = solarFestival(for: date) {
            return solar
        }
        guard let lunar else { return nil }
        if mode == .simple {
            // 简洁模式仅显示初一、十五、节日和节气
            if lunar.day == 1 || lunar.day == 15 {
                return lunar.dayText
            }
            return nil
        }
        return lunar.dayText
    }
}
