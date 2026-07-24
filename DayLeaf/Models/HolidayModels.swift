import Foundation

struct HolidayConfig: Codable {
    var year: Int
    var region: String
    var holidays: [HolidayItem]
    var adjustedWorkdays: [HolidayItem]
}

struct HolidayItem: Codable {
    var date: String
    var name: String
    var type: String
}
