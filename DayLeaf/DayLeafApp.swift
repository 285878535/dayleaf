import SwiftUI

@main
struct DayLeafApp: App {
    @StateObject private var settings: SettingsStore
    @StateObject private var history: HistoryStore
    @StateObject private var customDays: CustomDayStore
    @StateObject private var viewModel: CalendarSelectionViewModel

    init() {
        let settings = SettingsStore()
        let history = HistoryStore()
        let customDays = CustomDayStore()
        _settings = StateObject(wrappedValue: settings)
        _history = StateObject(wrappedValue: history)
        _customDays = StateObject(wrappedValue: customDays)
        _viewModel = StateObject(wrappedValue: CalendarSelectionViewModel(settings: settings, customDays: customDays, history: history))
    }

    var body: some Scene {
        MenuBarExtra {
            MainCalendarPopover()
                .environmentObject(settings)
                .environmentObject(history)
                .environmentObject(customDays)
                .environmentObject(viewModel)
        } label: {
            Image(systemName: settings.statusBarIcon.symbolName)
        }
        .menuBarExtraStyle(.window)

        Window("设置", id: "settings") {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(history)
                .environmentObject(customDays)
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)

        Window("历史记录", id: "history") {
            HistoryListView()
                .environmentObject(viewModel)
                .environmentObject(history)
                .environmentObject(settings)
        }
        .windowResizability(.contentSize)
    }
}
