import SwiftUI

struct MainCalendarPopover: View {
    @EnvironmentObject var viewModel: CalendarSelectionViewModel
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.colorScheme) var colorScheme

    private var tokens: ThemeTokens {
        ThemeTokens.tokens(for: settings.theme, colorScheme: colorScheme)
    }

    private var compact: Bool {
        settings.viewMode == .single
    }

    private var panelWidth: CGFloat {
        switch settings.viewMode {
        case .single: return 460
        case .double: return 720
        case .triple: return 1020
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CalendarToolbarView(tokens: tokens)
                QuickSelectBar(tokens: tokens)

                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.months(count: settings.viewMode.monthCount), id: \.self) { month in
                        MonthCalendarView(monthDate: month, tokens: tokens, compact: compact)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)

                DateRangeSummaryView(tokens: tokens, compact: compact)
            }
            .frame(width: panelWidth)
            .background(tokens.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(tokens.border, lineWidth: 1))
            .shadow(color: tokens.shadow, radius: 24, y: 8)

            if let message = viewModel.toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .padding(.bottom, 90)
                }
                .frame(width: panelWidth)
                .animation(.easeInOut(duration: 0.15), value: viewModel.toastMessage)
            }
        }
        .padding(12)
        .onAppear { viewModel.resetForPopoverOpen() }
    }
}
