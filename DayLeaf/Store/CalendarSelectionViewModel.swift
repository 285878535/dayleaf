import Foundation
import AppKit
import Combine

final class CalendarSelectionViewModel: ObservableObject {
    @Published var anchorMonth: Date
    @Published var selection: DateRangeSelection?
    @Published var dragAnchorDate: Date?
    @Published var isDragging: Bool = false
    @Published var clickPendingStart: Date?
    @Published var stats: DateStats = DateStats()
    @Published var toastMessage: String?
    /// 每次远程节假日数据刷新成功后自增，用于驱动依赖 holidayService 的视图重新取数。
    @Published private(set) var holidayRefreshTick: Int = 0

    private let settings: SettingsStore
    let customDays: CustomDayStore
    private let history: HistoryStore
    private let holidayService = HolidayService.shared
    private var yearsBeingFetched: Set<Int> = []

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()

    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore, customDays: CustomDayStore, history: HistoryStore) {
        self.settings = settings
        self.customDays = customDays
        self.history = history
        self.anchorMonth = calendar.startOfDay(for: Date())

        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recomputeStats() }
            .store(in: &cancellables)
        customDays.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recomputeStats() }
            .store(in: &cancellables)

        $anchorMonth
            .map { [calendar] date in calendar.component(.year, from: date) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] year in self?.ensureHolidayData(for: year) }
            .store(in: &cancellables)
    }

    /// 年份切换到本地没有数据的年份时，如果开启了自动更新，尝试从远程拉取。
    private func ensureHolidayData(for year: Int) {
        guard settings.autoUpdateHolidayData else { return }
        guard !holidayService.hasData(forYear: year) else { return }
        guard !yearsBeingFetched.contains(year) else { return }
        yearsBeingFetched.insert(year)

        Task { [weak self] in
            guard let self else { return }
            let success = await self.holidayService.refreshFromRemote(year: year)
            await MainActor.run {
                self.yearsBeingFetched.remove(year)
                guard success else { return }
                self.holidayRefreshTick += 1
                self.recomputeStats()
            }
        }
    }

    /// 供设置页"立即更新"按钮调用，无视是否已有本地数据，强制刷新指定年份。
    @discardableResult
    func forceRefreshHolidayData(for year: Int) async -> Bool {
        let success = await holidayService.refreshFromRemote(year: year)
        if success {
            await MainActor.run {
                self.holidayRefreshTick += 1
                self.recomputeStats()
            }
        }
        return success
    }

    var calculator: WorkdayCalculator {
        WorkdayCalculator(settings: settings, customDays: customDays)
    }

    var gridBuilder: CalendarGridBuilder {
        CalendarGridBuilder(settings: settings, calculator: calculator)
    }

    func months(count: Int) -> [Date] {
        (0..<count).compactMap { calendar.date(byAdding: .month, value: $0, to: anchorMonth) }
    }

    // MARK: - Navigation

    func goToPreviousMonth() {
        if let date = calendar.date(byAdding: .month, value: -1, to: anchorMonth) {
            anchorMonth = date
        }
    }

    func goToNextMonth() {
        if let date = calendar.date(byAdding: .month, value: 1, to: anchorMonth) {
            anchorMonth = date
        }
    }

    func goToToday() {
        anchorMonth = calendar.startOfDay(for: Date())
    }

    private var lastOpenedDay: Date?

    /// 面板每次弹出时调用：跨天后回到当月并清空上次的选择，同一天内保留。
    func resetForPopoverOpen() {
        let today = calendar.startOfDay(for: Date())
        guard lastOpenedDay != today else { return }
        lastOpenedDay = today
        anchorMonth = today
        selection = nil
        clickPendingStart = nil
        dragAnchorDate = nil
        isDragging = false
        stats = DateStats()
    }

    func selectYear(_ year: Int) {
        var comps = calendar.dateComponents([.year, .month], from: anchorMonth)
        comps.year = year
        if let date = calendar.date(from: comps) {
            anchorMonth = date
        }
    }

    func selectMonth(_ month: Int) {
        var comps = calendar.dateComponents([.year, .month], from: anchorMonth)
        comps.month = month
        if let date = calendar.date(from: comps) {
            anchorMonth = date
        }
    }

    // MARK: - Drag selection

    func handleDragStart(_ date: Date) {
        isDragging = true
        dragAnchorDate = date
        clickPendingStart = nil
        selection = DateRangeSelection(startDate: date, endDate: date)
        recomputeStats()
    }

    func handleDragUpdate(_ date: Date) {
        guard isDragging, let anchor = dragAnchorDate else { return }
        selection = DateRangeSelection(startDate: anchor, endDate: date).normalized
        recomputeStats()
    }

    func handleDragEnd() {
        guard isDragging else { return }
        isDragging = false
        dragAnchorDate = nil
        commitSelectionToHistory()
    }

    // MARK: - Click selection

    func handleClick(_ date: Date) {
        if let start = clickPendingStart {
            selection = DateRangeSelection(startDate: start, endDate: date).normalized
            clickPendingStart = nil
            recomputeStats()
            commitSelectionToHistory()
        } else {
            clickPendingStart = date
            selection = DateRangeSelection(startDate: date, endDate: date)
            recomputeStats()
        }
    }

    // MARK: - Quick select

    func applyQuickSelect(_ option: QuickSelectOption) {
        let today = calendar.startOfDay(for: Date())
        switch option {
        case .today:
            selection = DateRangeSelection(startDate: today, endDate: today)
        case .thisWeek:
            if let interval = calendar.dateInterval(of: .weekOfYear, for: today) {
                let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
                selection = DateRangeSelection(startDate: interval.start, endDate: end)
            }
        case .thisMonth:
            if let interval = calendar.dateInterval(of: .month, for: today) {
                let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
                selection = DateRangeSelection(startDate: interval.start, endDate: end)
            }
        case .nextMonth:
            if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: today),
               let interval = calendar.dateInterval(of: .month, for: nextMonthDate) {
                let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
                selection = DateRangeSelection(startDate: interval.start, endDate: end)
            }
        case .next7:
            let end = calendar.date(byAdding: .day, value: 6, to: today) ?? today
            selection = DateRangeSelection(startDate: today, endDate: end)
        case .next14:
            let end = calendar.date(byAdding: .day, value: 13, to: today) ?? today
            selection = DateRangeSelection(startDate: today, endDate: end)
        case .next30:
            let end = calendar.date(byAdding: .day, value: 29, to: today) ?? today
            selection = DateRangeSelection(startDate: today, endDate: end)
        case .thisQuarter:
            let month = calendar.component(.month, from: today)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var startComps = calendar.dateComponents([.year], from: today)
            startComps.month = quarterStartMonth
            startComps.day = 1
            if let start = calendar.date(from: startComps),
               let quarterEndMonthDate = calendar.date(byAdding: .month, value: 3, to: start),
               let end = calendar.date(byAdding: .day, value: -1, to: quarterEndMonthDate) {
                selection = DateRangeSelection(startDate: start, endDate: end)
            }
        }
        clickPendingStart = nil
        if let selection { anchorMonth = selection.startDate }
        recomputeStats()
        commitSelectionToHistory()
    }

    func applyCustomRange(start: Date, end: Date) {
        selection = DateRangeSelection(startDate: start, endDate: end).normalized
        anchorMonth = selection?.startDate ?? anchorMonth
        recomputeStats()
        commitSelectionToHistory()
    }

    // MARK: - Stats & history

    func recomputeStats() {
        guard let selection else {
            stats = DateStats()
            return
        }
        stats = calculator.stats(for: selection)
    }

    private func commitSelectionToHistory() {
        guard let selection else { return }
        let record = HistoryRecord(
            id: UUID().uuidString,
            startDate: Self.isoFormatter.string(from: selection.normalized.startDate),
            endDate: Self.isoFormatter.string(from: selection.normalized.endDate),
            totalDays: stats.totalDays,
            workdays: stats.workdays,
            restDays: stats.restDays,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            note: ""
        )
        history.add(record, limit: settings.historyLimit)
    }

    func restoreFromHistory(_ record: HistoryRecord) {
        guard let start = Self.isoFormatter.date(from: record.startDate),
              let end = Self.isoFormatter.date(from: record.endDate) else { return }
        selection = DateRangeSelection(startDate: start, endDate: end)
        anchorMonth = start
        recomputeStats()
    }

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        return f
    }()

    // MARK: - Copy

    func copyResult(template: CopyTemplateType, settingsStore: SettingsStore) {
        guard let selection else { return }
        let text = CopyTemplateFormatter.format(
            template: template,
            selection: selection.normalized,
            stats: stats,
            dateFormat: settingsStore.dateFormatOption,
            customTemplate: settingsStore.customTemplateText
        )
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        showToast("已复制到剪贴板")
    }

    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if self?.toastMessage == message {
                self?.toastMessage = nil
            }
        }
    }
}
