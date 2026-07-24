import Foundation

/// Loads bundled + user-imported holiday configs, keyed by year.
final class HolidayService {
    static let shared = HolidayService()

    private var configsByYear: [Int: HolidayConfig] = [:]
    private var holidayLookup: [Int: [String: HolidayItem]] = [:]
    private var adjustedWorkdayLookup: [Int: [String: HolidayItem]] = [:]

    private let userDataURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DayLeaf", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("HolidayConfigs.json")
    }()

    private init() {
        loadBundledConfigs()
        loadUserConfigs()
    }

    private func loadBundledConfigs() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else { return }
        let decoder = JSONDecoder()
        for url in urls where url.lastPathComponent.hasPrefix("Holidays") {
            guard let data = try? Data(contentsOf: url),
                  let config = try? decoder.decode(HolidayConfig.self, from: data) else { continue }
            register(config)
        }
    }

    private func loadUserConfigs() {
        guard let data = try? Data(contentsOf: userDataURL),
              let configs = try? JSONDecoder().decode([HolidayConfig].self, from: data) else { return }
        for config in configs {
            register(config)
        }
    }

    private func register(_ config: HolidayConfig) {
        configsByYear[config.year] = config
        var holidays: [String: HolidayItem] = [:]
        for item in config.holidays { holidays[item.date] = item }
        holidayLookup[config.year] = holidays

        var adjusted: [String: HolidayItem] = [:]
        for item in config.adjustedWorkdays { adjusted[item.date] = item }
        adjustedWorkdayLookup[config.year] = adjusted
    }

    func hasData(forYear year: Int) -> Bool {
        configsByYear[year] != nil
    }

    func holidayItem(for date: Date) -> HolidayItem? {
        let (year, key) = Self.key(for: date)
        return holidayLookup[year]?[key]
    }

    func adjustedWorkdayItem(for date: Date) -> HolidayItem? {
        let (year, key) = Self.key(for: date)
        return adjustedWorkdayLookup[year]?[key]
    }

    /// 手动导入自定义节假日配置(合并已有数据),并持久化到本地
    func importConfig(_ config: HolidayConfig) {
        register(config)
        persistUserConfigs()
    }

    private func persistUserConfigs() {
        let configs = Array(configsByYear.values)
        guard let data = try? JSONEncoder().encode(configs) else { return }
        try? data.write(to: userDataURL)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        return f
    }()

    private static func key(for date: Date) -> (year: Int, key: String) {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: date)
        return (year, formatter.string(from: date))
    }

    // MARK: - Remote fetch

    /// 社区维护的中国法定节假日数据集(基于国办通知整理),按年份发布 JSON。
    /// 非官方接口，仅作为"实时获取"的数据来源，失败时保留本地已有数据不受影响。
    private static func remoteURLs(forYear year: Int) -> [URL] {
        [
            URL(string: "https://raw.githubusercontent.com/NateScarlet/holiday-cn/master/\(year).json"),
            URL(string: "https://cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master/\(year).json")
        ].compactMap { $0 }
    }

    enum RemoteFetchError: Error {
        case invalidResponse
        case decodingFailed
    }

    private struct RemoteHolidayYear: Decodable {
        struct Day: Decodable {
            let name: String
            let date: String
            let isOffDay: Bool
        }
        let year: Int
        let days: [Day]

        func toHolidayConfig() -> HolidayConfig {
            var holidays: [HolidayItem] = []
            var adjustedWorkdays: [HolidayItem] = []
            for day in days {
                if day.isOffDay {
                    holidays.append(HolidayItem(date: day.date, name: day.name, type: "holiday"))
                } else {
                    adjustedWorkdays.append(HolidayItem(date: day.date, name: day.name + "调休上班", type: "workday"))
                }
            }
            return HolidayConfig(year: year, region: "CN", holidays: holidays, adjustedWorkdays: adjustedWorkdays)
        }
    }

    private func fetchRemoteConfig(year: Int) async throws -> HolidayConfig {
        var lastError: Error = RemoteFetchError.invalidResponse
        for url in Self.remoteURLs(forYear: year) {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    lastError = RemoteFetchError.invalidResponse
                    continue
                }
                let remote = try JSONDecoder().decode(RemoteHolidayYear.self, from: data)
                return remote.toHolidayConfig()
            } catch {
                lastError = error
                continue
            }
        }
        throw lastError
    }

    /// 尝试从远程数据源刷新指定年份的节假日数据；失败时不影响已有本地数据。
    @discardableResult
    func refreshFromRemote(year: Int) async -> Bool {
        guard let config = try? await fetchRemoteConfig(year: year) else { return false }
        register(config)
        persistUserConfigs()
        return true
    }
}
