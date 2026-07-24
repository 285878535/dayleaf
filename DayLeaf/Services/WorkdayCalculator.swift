import Foundation

/// Computes workday/rest-day status per the priority rules in the spec:
/// 1. 用户自定义工作日  2. 用户自定义休息日  3. 中国调休工作日
/// 4. 中国法定节假日   5. 工作规则(双休/单休/大小周/自定义每周)  6. 默认周一至周五
struct WorkdayCalculator {
    let settings: SettingsStore
    let customDays: CustomDayStore
    let holidayService: HolidayService = .shared

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        return f
    }()

    struct DayResult {
        let holidayType: HolidayType
        let holidayName: String?
        let isWorkday: Bool
    }

    func evaluate(_ date: Date) -> DayResult {
        let dateKey = Self.dayFormatter.string(from: date)

        if let custom = customDays.rule(forDateKey: dateKey) {
            return DayResult(
                holidayType: custom.isWorkday ? .customWorkday : .customRestDay,
                holidayName: nil,
                isWorkday: custom.isWorkday
            )
        }

        if settings.showAdjustedWorkday, let adjusted = holidayService.adjustedWorkdayItem(for: date) {
            return DayResult(holidayType: .adjustedWorkday, holidayName: adjusted.name, isWorkday: true)
        }

        if settings.showChinaHolidays, let holiday = holidayService.holidayItem(for: date) {
            return DayResult(holidayType: .holiday, holidayName: holiday.name, isWorkday: false)
        }

        let isWorkday = ruleBasedWorkday(for: date)
        return DayResult(holidayType: .none, holidayName: nil, isWorkday: isWorkday)
    }

    private func ruleBasedWorkday(for date: Date) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let weekday = cal.component(.weekday, from: date) // 1 = Sunday ... 7 = Saturday

        switch settings.workRuleType {
        case .doubleRest:
            return weekday != 1 && weekday != 7
        case .singleRest:
            return weekday != 1
        case .bigSmallWeek:
            return bigSmallWeekWorkday(for: date, weekday: weekday, calendar: cal)
        case .custom:
            let index = (weekday + 5) % 7 // 0 = Monday ... 6 = Sunday
            return settings.customWeekWorkdays[index]
        }
    }

    private func bigSmallWeekWorkday(for date: Date, weekday: Int, calendar: Calendar) -> Bool {
        guard weekday != 1 else { return false } // 周日始终休息

        guard let startWeekDate = Self.dayFormatter.date(from: settings.bigSmallWeekStartDate) else {
            return weekday != 7
        }
        let startOfStartWeek = calendar.dateInterval(of: .weekOfYear, for: startWeekDate)?.start ?? startWeekDate
        let startOfCurrentWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weeksBetween = calendar.dateComponents([.weekOfYear], from: startOfStartWeek, to: startOfCurrentWeek).weekOfYear ?? 0

        let isEvenOffset = weeksBetween % 2 == 0
        let isBigWeek = settings.bigSmallWeekStartsBig ? isEvenOffset : !isEvenOffset

        if weekday == 7 {
            return !isBigWeek // 大周周六休息,小周周六上班
        }
        return true
    }

    func stats(for range: DateRangeSelection) -> DateStats {
        let normalized = range.normalized
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current

        var stats = DateStats()
        var current = cal.startOfDay(for: normalized.startDate)
        let end = cal.startOfDay(for: normalized.endDate)

        while current <= end {
            stats.totalDays += 1
            let result = evaluate(current)

            if result.isWorkday {
                stats.workdays += 1
            } else {
                stats.restDays += 1
            }

            switch result.holidayType {
            case .holiday: stats.holidays += 1
            case .adjustedWorkday: stats.adjustedWorkdays += 1
            case .customRestDay: stats.customRestDays += 1
            case .customWorkday: stats.customWorkdays += 1
            case .none: break
            }

            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return stats
    }
}
