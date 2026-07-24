import SwiftUI

struct DateRangeSummaryView: View {
    @EnvironmentObject var viewModel: CalendarSelectionViewModel
    @EnvironmentObject var settings: SettingsStore
    let tokens: ThemeTokens
    let compact: Bool

    private var weekdaySymbol: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "M月d日（EEEE）"
        f.locale = Locale(identifier: "zh_CN")
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }

    private var rangeText: String {
        guard let selection = viewModel.selection?.normalized else { return "尚未选择日期范围" }
        return "\(weekdaySymbol.string(from: selection.startDate)) 至 \(weekdaySymbol.string(from: selection.endDate))"
    }

    private var catSize: CGSize {
        compact ? CGSize(width: 84, height: 70) : CGSize(width: 120, height: 98)
    }

    private var copyButtonLabel: some View {
        Label("复制", systemImage: "doc.on.doc")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .frame(height: 30)
    }

    /// 用条件分支切换"可点击的 Menu"和"纯展示的灰色占位"两种完全不同的视图，
    /// 而不是对同一个 Menu 切换 .disabled —— 后者在 macOS 上有已知的 AppKit
    /// 状态不同步问题，disabled 从 true 变回 false 后菜单可能一直点不开。
    private var copyMenu: some View {
        Group {
            if viewModel.selection != nil {
                Menu {
                    ForEach(CopyTemplateType.allCases) { template in
                        Button(template.displayName) {
                            viewModel.copyResult(template: template, settingsStore: settings)
                        }
                    }
                } label: {
                    copyButtonLabel
                        .background(RoundedRectangle(cornerRadius: 8).fill(tokens.primary))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            } else {
                copyButtonLabel
                    .background(RoundedRectangle(cornerRadius: 8).fill(tokens.primary.opacity(0.4)))
                    .fixedSize()
            }
        }
    }

    private var compactStatsText: String {
        let total = String(viewModel.stats.totalDays)
        let workdays = String(viewModel.stats.workdays)
        let rest = String(viewModel.stats.restDays)
        return "共 " + total + " 天 · 工作日 " + workdays + " · 休息日 " + rest
    }

    private var catImage: some View {
        Group {
            if tokens.showsCat {
                Image("CatDecoration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: catSize.width, height: catSize.height)
            }
        }
    }

    var body: some View {
        Group {
            if compact {
                HStack(alignment: .center, spacing: 12) {
                    catImage

                    VStack(alignment: .leading, spacing: 6) {
                        Text("已选择日期范围")
                            .font(.system(size: 10))
                            .foregroundColor(tokens.textSecondary)
                        Text(rangeText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(tokens.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            Text(compactStatsText)
                                .font(.system(size: 11))
                                .foregroundColor(tokens.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 4)
                            copyMenu
                        }
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: 12) {
                    catImage

                    VStack(alignment: .leading, spacing: 6) {
                        Text("已选择日期范围")
                            .font(.system(size: 11))
                            .foregroundColor(tokens.textSecondary)
                        Text(rangeText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(tokens.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("共 " + String(viewModel.stats.totalDays) + " 天")
                            .font(.system(size: 12))
                            .foregroundColor(tokens.textSecondary)

                        HStack(spacing: 8) {
                            StatsCardView(icon: "calendar.badge.clock", title: "总天数", value: viewModel.stats.totalDays, tokens: tokens)
                            StatsCardView(icon: "briefcase.fill", title: "工作日", value: viewModel.stats.workdays, tokens: tokens)
                            StatsCardView(icon: "cup.and.saucer.fill", title: "休息日", value: viewModel.stats.restDays, tokens: tokens)
                            if settings.showChinaHolidays {
                                StatsCardView(icon: "flag.fill", title: "法定节假日", value: viewModel.stats.holidays, tokens: tokens)
                            }
                            if settings.showAdjustedWorkday {
                                StatsCardView(icon: "arrow.triangle.2.circlepath", title: "调休工作日", value: viewModel.stats.adjustedWorkdays, tokens: tokens)
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    copyMenu
                }
            }
        }
        .padding(14)
        .background(tokens.primarySoft)
    }
}
