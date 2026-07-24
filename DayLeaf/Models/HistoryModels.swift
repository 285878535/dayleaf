import Foundation

struct HistoryRecord: Codable, Identifiable, Equatable {
    var id: String
    var startDate: String
    var endDate: String
    var totalDays: Int
    var workdays: Int
    var restDays: Int
    var createdAt: String
    var note: String
}

struct CustomDayRule: Codable, Identifiable, Equatable {
    var id: String
    var date: String
    var isWorkday: Bool
}
