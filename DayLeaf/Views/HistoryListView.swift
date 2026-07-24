import SwiftUI

struct HistoryListView: View {
    @EnvironmentObject var viewModel: CalendarSelectionViewModel
    @EnvironmentObject var history: HistoryStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var tokens: ThemeTokens {
        ThemeTokens.tokens(for: settings.theme, colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("历史记录")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("完成") { dismiss() }
            }
            .padding()

            if history.records.isEmpty {
                Spacer()
                Text("暂无历史记录")
                    .foregroundColor(tokens.textTertiary)
                Spacer()
            } else {
                List {
                    ForEach(history.records) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(record.startDate) 至 \(record.endDate)")
                                .font(.system(size: 13, weight: .medium))
                            Text("共 " + String(record.totalDays) + " 天，工作日 " + String(record.workdays) + " 天，休息日 " + String(record.restDays) + " 天")
                                .font(.system(size: 11))
                                .foregroundColor(tokens.textSecondary)
                            HStack(spacing: 12) {
                                Button("恢复选择") {
                                    viewModel.restoreFromHistory(record)
                                    dismiss()
                                }
                                Button("删除", role: .destructive) {
                                    history.remove(record)
                                }
                            }
                            .font(.system(size: 11))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(width: 360, height: 480)
    }
}
