import Foundation

enum HolidayType: String, Codable {
    case holiday
    case adjustedWorkday
    case customRestDay
    case customWorkday
    case none
}

struct CalendarDay: Identifiable {
    let id: String
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let weekday: Int
    let solarDay: Int
    let lunarText: String?
    let festivalText: String?
    let holidayType: HolidayType
    let holidayName: String?
    let isWorkday: Bool
}

struct DateRangeSelection: Codable, Equatable {
    var startDate: Date
    var endDate: Date

    var normalized: DateRangeSelection {
        startDate <= endDate ? self : DateRangeSelection(startDate: endDate, endDate: startDate)
    }
}

struct DateStats: Codable, Equatable {
    var totalDays: Int = 0
    var workdays: Int = 0
    var restDays: Int = 0
    var holidays: Int = 0
    var adjustedWorkdays: Int = 0
    var customRestDays: Int = 0
    var customWorkdays: Int = 0
}
