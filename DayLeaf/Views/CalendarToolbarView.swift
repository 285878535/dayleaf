import SwiftUI
import AppKit

struct CalendarToolbarView: View {
    @EnvironmentObject var viewModel: CalendarSelectionViewModel
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.openWindow) var openWindow
    let tokens: ThemeTokens

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(WorkRuleType.allCases) { rule in
                    Button(rule.displayName) { settings.workRuleType = rule }
                }
            } label: {
                Text(settings.workRuleType.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(tokens.textPrimary)
                    .frame(width: 68, height: 30)
                    .background(RoundedRectangle(cornerRadius: 8).fill(tokens.primarySoft))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer(minLength: 4)

            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)

            Menu {
                ForEach(yearOptions, id: \.self) { year in
                    Button(String(year) + "年") { viewModel.selectYear(year) }
                }
            } label: {
                Text(String(calendar.component(.year, from: viewModel.anchorMonth)) + "年")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tokens.textPrimary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Menu {
                ForEach(1...12, id: \.self) { month in
                    Button(String(month) + "月") { viewModel.selectMonth(month) }
                }
            } label: {
                Text(String(calendar.component(.month, from: viewModel.anchorMonth)) + "月")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tokens.textPrimary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)

            Spacer(minLength: 4)

            Button("今天") {
                viewModel.goToToday()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(tokens.primaryDeep)
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(RoundedRectangle(cornerRadius: 8).fill(tokens.primarySoft))
            .fixedSize()

            Button {
                openWindow(id: "history")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(.plain)
            .fixedSize()

            Button {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .foregroundColor(tokens.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(tokens.toolbarBackground)
    }

    private var yearOptions: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 5)...(current + 5))
    }
}
