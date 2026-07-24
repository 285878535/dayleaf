import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var history: HistoryStore
    @EnvironmentObject var customDays: CustomDayStore
    @EnvironmentObject var viewModel: CalendarSelectionViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var tokens: ThemeTokens {
        ThemeTokens.tokens(for: settings.theme, colorScheme: colorScheme)
    }

    @State private var showImporter = false
    @State private var importErrorMessage: String?
    @State private var newCustomDate = Date()
    @State private var newCustomIsWorkday = true
    @State private var isRefreshingHolidayData = false
    @State private var refreshStatusMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("设置")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("完成") { dismiss() }
            }
            .padding()

            Form {
                Section("外观") {
                    Picker("主题", selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker("默认视图", selection: $settings.viewMode) {
                        ForEach(ViewMode.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker("状态栏图标", selection: $settings.statusBarIcon) {
                        ForEach(StatusBarIconOption.allCases) { Text($0.displayName).tag($0) }
                    }
                    Toggle("开机启动", isOn: $settings.launchAtLogin)
                }

                Section("日历") {
                    Picker("农历显示", selection: $settings.lunarDisplayMode) {
                        ForEach(LunarDisplayMode.allCases) { Text($0.displayName).tag($0) }
                    }
                    Toggle("中国放假提示", isOn: $settings.showChinaHolidays)
                    Toggle("调休工作日提示", isOn: $settings.showAdjustedWorkday)
                    Picker("起始星期", selection: $settings.weekStart) {
                        ForEach(WeekStartDay.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker("日期格式", selection: $settings.dateFormatOption) {
                        ForEach(DateFormatOption.allCases) { Text($0.displayName).tag($0) }
                    }
                }

                Section("工作规则") {
                    Picker("工作规则", selection: $settings.workRuleType) {
                        ForEach(WorkRuleType.allCases) { Text($0.displayName).tag($0) }
                    }

                    if settings.workRuleType == .bigSmallWeek {
                        DatePicker("起始周日期", selection: bigSmallStartBinding, displayedComponents: .date)
                        Toggle("起始周为大周", isOn: $settings.bigSmallWeekStartsBig)
                    }

                    if settings.workRuleType == .custom {
                        ForEach(0..<7, id: \.self) { index in
                            Toggle(weekdayName(index), isOn: customWeekBinding(index))
                        }
                    }
                }

                Section("自定义日期") {
                    DatePicker("日期", selection: $newCustomDate, displayedComponents: .date)
                    Picker("类型", selection: $newCustomIsWorkday) {
                        Text("工作日").tag(true)
                        Text("休息日").tag(false)
                    }
                    .pickerStyle(.segmented)
                    Button("添加规则") { addCustomRule() }

                    ForEach(customDays.rules) { rule in
                        HStack {
                            Text(rule.date)
                            Spacer()
                            Text(rule.isWorkday ? "工作日" : "休息日")
                                .foregroundColor(tokens.textSecondary)
                            Button(role: .destructive) {
                                customDays.removeRule(dateKey: rule.date)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }

                Section("复制") {
                    Picker("默认复制模板", selection: $settings.copyTemplateType) {
                        ForEach(CopyTemplateType.allCases) { Text($0.displayName).tag($0) }
                    }
                    if settings.copyTemplateType == .custom {
                        TextField("自定义模板", text: $settings.customTemplateText)
                        Text("支持变量：{startDate} {endDate} {totalDays} {workdays} {restDays} {holidays} {adjustedWorkdays} {dateRange} {lunarStart} {lunarEnd}")
                            .font(.system(size: 10))
                            .foregroundColor(tokens.textTertiary)
                    }
                }

                Section("数据") {
                    Picker("历史记录数量", selection: $settings.historyLimit) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("50").tag(50)
                    }

                    Toggle("自动更新节假日数据", isOn: $settings.autoUpdateHolidayData)
                    HStack {
                        Button(isRefreshingHolidayData ? "更新中…" : "立即更新当前年份数据") {
                            refreshCurrentYear()
                        }
                        .disabled(isRefreshingHolidayData)
                        if isRefreshingHolidayData {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    if let refreshStatusMessage {
                        Text(refreshStatusMessage)
                            .font(.system(size: 11))
                            .foregroundColor(tokens.textSecondary)
                    }
                    Text("数据来自社区维护的开源节假日数据集（非官方接口），切换到本地没有数据的年份时会自动尝试联网获取；获取失败不影响已有数据。")
                        .font(.system(size: 10))
                        .foregroundColor(tokens.textTertiary)

                    Button("导入节假日 JSON") { showImporter = true }
                    if let importErrorMessage {
                        Text(importErrorMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }

                    Button("清空历史记录", role: .destructive) {
                        history.clearAll()
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 420, height: 560)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
    }

    private var bigSmallStartBinding: Binding<Date> {
        Binding(
            get: {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f.date(from: settings.bigSmallWeekStartDate) ?? Date()
            },
            set: { newValue in
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                settings.bigSmallWeekStartDate = f.string(from: newValue)
            }
        )
    }

    private func customWeekBinding(_ index: Int) -> Binding<Bool> {
        Binding(
            get: { settings.customWeekWorkdays.indices.contains(index) ? settings.customWeekWorkdays[index] : true },
            set: { newValue in
                var days = settings.customWeekWorkdays
                while days.count < 7 { days.append(true) }
                days[index] = newValue
                settings.customWeekWorkdays = days
            }
        )
    }

    private func weekdayName(_ index: Int) -> String {
        ["周一", "周二", "周三", "周四", "周五", "周六", "周日"][index]
    }

    private func refreshCurrentYear() {
        let year = Calendar(identifier: .gregorian).component(.year, from: viewModel.anchorMonth)
        isRefreshingHolidayData = true
        refreshStatusMessage = nil
        Task {
            let success = await viewModel.forceRefreshHolidayData(for: year)
            await MainActor.run {
                isRefreshingHolidayData = false
                refreshStatusMessage = success ? "\(year) 年节假日数据已更新" : "更新失败，请检查网络后重试"
            }
        }
    }

    private func addCustomRule() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        let key = f.string(from: newCustomDate)
        customDays.setRule(dateKey: key, isWorkday: newCustomIsWorkday)
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = "无法访问所选文件"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(HolidayConfig.self, from: data)
                HolidayService.shared.importConfig(config)
                importErrorMessage = nil
            } catch {
                importErrorMessage = "本地 JSON 损坏，已回退默认配置，请重新导入"
            }
        case .failure:
            importErrorMessage = "导入失败"
        }
    }
}
