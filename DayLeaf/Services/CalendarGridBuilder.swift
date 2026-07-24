import Foundation

/// Builds the 6x7 day grid for a given month.
struct CalendarGridBuilder {
    let settings: SettingsStore
    let calculator: WorkdayCalculator
    let lunarService = LunarCalendarService.shared

    func buildGrid(for monthDate: Date) -> [CalendarDay] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        cal.firstWeekday = settings.weekStart.firstWeekdayIndex

        guard let monthInterval = cal.dateInterval(of: .month, for: monthDate) else { return [] }
        let firstOfMonth = monthInterval.start

        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let leadingOffset = (firstWeekday - cal.firstWeekday + 7) % 7
        guard let gridStart = cal.date(byAdding: .day, value: -leadingOffset, to: firstOfMonth) else { return [] }

        let today = cal.startOfDay(for: Date())

        var days: [CalendarDay] = []
        for i in 0..<42 {
            guard let date = cal.date(byAdding: .day, value: i, to: gridStart) else { continue }
            let isCurrentMonth = cal.isDate(date, equalTo: monthDate, toGranularity: .month)
            let isToday = cal.isDate(date, inSameDayAs: today)
            let weekday = cal.component(.weekday, from: date)
            let solarDay = cal.component(.day, from: date)

            let result = calculator.evaluate(date)
            let text = lunarService.displayText(for: date, holidayName: result.holidayName, mode: settings.lunarDisplayMode)
            let festival = (result.holidayName != nil) ? nil : lunarService.lunarInfo(for: date)?.lunarFestival

            days.append(CalendarDay(
                id: Self.identifier(for: date),
                date: date,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                weekday: weekday,
                solarDay: solarDay,
                lunarText: text,
                festivalText: festival,
                holidayType: result.holidayType,
                holidayName: result.holidayName,
                isWorkday: result.isWorkday
            ))
        }
        return days
    }

    static func identifier(for date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }
}
