import Foundation
import Combine
import ServiceManagement

final class SettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var theme: AppTheme { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    @Published var viewMode: ViewMode { didSet { defaults.set(viewMode.rawValue, forKey: Keys.viewMode) } }
    @Published var lunarDisplayMode: LunarDisplayMode { didSet { defaults.set(lunarDisplayMode.rawValue, forKey: Keys.lunarMode) } }
    @Published var showChinaHolidays: Bool { didSet { defaults.set(showChinaHolidays, forKey: Keys.showHolidays) } }
    @Published var showAdjustedWorkday: Bool { didSet { defaults.set(showAdjustedWorkday, forKey: Keys.showAdjusted) } }
    @Published var weekStart: WeekStartDay { didSet { defaults.set(weekStart.rawValue, forKey: Keys.weekStart) } }
    @Published var workRuleType: WorkRuleType { didSet { defaults.set(workRuleType.rawValue, forKey: Keys.workRule) } }
    @Published var customWeekWorkdays: [Bool] { didSet { defaults.set(customWeekWorkdays, forKey: Keys.customWeek) } }
    @Published var bigSmallWeekStartDate: String { didSet { defaults.set(bigSmallWeekStartDate, forKey: Keys.bigSmallStart) } }
    @Published var bigSmallWeekStartsBig: Bool { didSet { defaults.set(bigSmallWeekStartsBig, forKey: Keys.bigSmallIsBig) } }
    @Published var dateFormatOption: DateFormatOption { didSet { defaults.set(dateFormatOption.rawValue, forKey: Keys.dateFormat) } }
    @Published var copyTemplateType: CopyTemplateType { didSet { defaults.set(copyTemplateType.rawValue, forKey: Keys.copyTemplate) } }
    @Published var customTemplateText: String { didSet { defaults.set(customTemplateText, forKey: Keys.customTemplate) } }
    @Published var historyLimit: Int { didSet { defaults.set(historyLimit, forKey: Keys.historyLimit) } }
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            applyLoginItem()
        }
    }
    @Published var statusBarIcon: StatusBarIconOption { didSet { defaults.set(statusBarIcon.rawValue, forKey: Keys.statusBarIcon) } }
    @Published var autoUpdateHolidayData: Bool { didSet { defaults.set(autoUpdateHolidayData, forKey: Keys.autoUpdateHolidayData) } }

    private enum Keys {
        static let theme = "settings.theme"
        static let viewMode = "settings.viewMode"
        static let lunarMode = "settings.lunarMode"
        static let showHolidays = "settings.showHolidays"
        static let showAdjusted = "settings.showAdjusted"
        static let weekStart = "settings.weekStart"
        static let workRule = "settings.workRule"
        static let customWeek = "settings.customWeek"
        static let bigSmallStart = "settings.bigSmallStart"
        static let bigSmallIsBig = "settings.bigSmallIsBig"
        static let dateFormat = "settings.dateFormat"
        static let copyTemplate = "settings.copyTemplate"
        static let customTemplate = "settings.customTemplate"
        static let historyLimit = "settings.historyLimit"
        static let launchAtLogin = "settings.launchAtLogin"
        static let statusBarIcon = "settings.statusBarIcon"
        static let autoUpdateHolidayData = "settings.autoUpdateHolidayData"
    }

    init() {
        theme = AppTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .fresh
        viewMode = ViewMode(rawValue: defaults.string(forKey: Keys.viewMode) ?? "") ?? .double
        lunarDisplayMode = LunarDisplayMode(rawValue: defaults.string(forKey: Keys.lunarMode) ?? "") ?? .full
        showChinaHolidays = defaults.object(forKey: Keys.showHolidays) as? Bool ?? true
        showAdjustedWorkday = defaults.object(forKey: Keys.showAdjusted) as? Bool ?? true
        weekStart = WeekStartDay(rawValue: defaults.string(forKey: Keys.weekStart) ?? "") ?? .monday
        workRuleType = WorkRuleType(rawValue: defaults.string(forKey: Keys.workRule) ?? "") ?? .doubleRest
        customWeekWorkdays = defaults.array(forKey: Keys.customWeek) as? [Bool] ?? [true, true, true, true, true, false, false]
        bigSmallWeekStartDate = defaults.string(forKey: Keys.bigSmallStart) ?? SettingsStore.defaultBigSmallStart()
        bigSmallWeekStartsBig = defaults.object(forKey: Keys.bigSmallIsBig) as? Bool ?? true
        dateFormatOption = DateFormatOption(rawValue: defaults.string(forKey: Keys.dateFormat) ?? "") ?? .dotted
        copyTemplateType = CopyTemplateType(rawValue: defaults.string(forKey: Keys.copyTemplate) ?? "") ?? .simple
        customTemplateText = defaults.string(forKey: Keys.customTemplate) ?? "{startDate} 至 {endDate}，共 {totalDays} 天"
        historyLimit = defaults.object(forKey: Keys.historyLimit) as? Int ?? 20
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        statusBarIcon = StatusBarIconOption(rawValue: defaults.string(forKey: Keys.statusBarIcon) ?? "") ?? .calendar
        autoUpdateHolidayData = defaults.object(forKey: Keys.autoUpdateHolidayData) as? Bool ?? true
    }

    private static func defaultBigSmallStart() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func applyLoginItem() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if launchAtLogin {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("LoginItem error: \(error)")
        }
    }
}
