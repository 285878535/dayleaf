import Foundation

enum CopyTemplateFormatter {
    static func format(
        template: CopyTemplateType,
        selection: DateRangeSelection,
        stats: DateStats,
        dateFormat: DateFormatOption,
        customTemplate: String
    ) -> String {
        let df = DateFormatter()
        df.dateFormat = dateFormat.dateFormat
        df.calendar = Calendar(identifier: .gregorian)
        df.timeZone = TimeZone.current

        let start = df.string(from: selection.startDate)
        let end = df.string(from: selection.endDate)
        let lunar = LunarCalendarService.shared
        let lunarStart = lunar.lunarInfo(for: selection.startDate)?.dayText ?? ""
        let lunarEnd = lunar.lunarInfo(for: selection.endDate)?.dayText ?? ""

        switch template {
        case .simple:
            return "\(start) 至 \(end)，共 \(stats.totalDays) 天"
        case .work:
            return "\(start) 至 \(end)，共 \(stats.totalDays) 天，实际工作日 \(stats.workdays) 天，休息日 \(stats.restDays) 天"
        case .leave:
            return "请假范围：\(start) 至 \(end)，需请假工作日 \(stats.workdays) 天"
        case .project:
            return "项目周期：\(start) 至 \(end)，总计 \(stats.totalDays) 天，其中工作日 \(stats.workdays) 天"
        case .markdown:
            return """
            | 日期范围 | 总天数 | 工作日 | 休息日 |
            |---|---:|---:|---:|
            | \(start) 至 \(end) | \(stats.totalDays) | \(stats.workdays) | \(stats.restDays) |
            """
        case .json:
            let dict: [String: Any] = [
                "startDate": isoDate(selection.startDate),
                "endDate": isoDate(selection.endDate),
                "totalDays": stats.totalDays,
                "workdays": stats.workdays,
                "restDays": stats.restDays,
                "holidays": stats.holidays,
                "adjustedWorkdays": stats.adjustedWorkdays
            ]
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return ""
        case .custom:
            return customTemplate
                .replacingOccurrences(of: "{startDate}", with: start)
                .replacingOccurrences(of: "{endDate}", with: end)
                .replacingOccurrences(of: "{totalDays}", with: "\(stats.totalDays)")
                .replacingOccurrences(of: "{workdays}", with: "\(stats.workdays)")
                .replacingOccurrences(of: "{restDays}", with: "\(stats.restDays)")
                .replacingOccurrences(of: "{holidays}", with: "\(stats.holidays)")
                .replacingOccurrences(of: "{adjustedWorkdays}", with: "\(stats.adjustedWorkdays)")
                .replacingOccurrences(of: "{dateRange}", with: "\(start) 至 \(end)")
                .replacingOccurrences(of: "{lunarStart}", with: lunarStart)
                .replacingOccurrences(of: "{lunarEnd}", with: lunarEnd)
        }
    }

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }
}
