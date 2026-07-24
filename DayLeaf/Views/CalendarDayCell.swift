import SwiftUI

struct CalendarDayCell: View {
    let day: CalendarDay
    let tokens: ThemeTokens
    let isSelectionStart: Bool
    let isSelectionEnd: Bool
    let isInSelection: Bool
    let compact: Bool

    private var solarSize: CGFloat { compact ? 15 : 18 }
    private var lunarSize: CGFloat { compact ? 9 : 11 }

    /// 调休工作日/自定义工作日虽然可能落在周末，但当天仍要按"上班"处理，
    /// 因此不应套用休息日的强调色，方便与真正的休息日区分。
    private var isForcedWorkday: Bool {
        day.holidayType == .adjustedWorkday || day.holidayType == .customWorkday
    }

    /// 法定节假日/自定义休息日才算"放假"，普通周末只是数字变色，不额外标注。
    private var isDeclaredRestDay: Bool {
        day.holidayType == .holiday || day.holidayType == .customRestDay
    }

    /// 相邻月的溢出格子即使日期是今天也不做"今天"高亮，避免多月视图出现两个"今"。
    private var isTodayCell: Bool {
        day.isToday && day.isCurrentMonth
    }

    private var solarColor: Color {
        guard day.isCurrentMonth else { return tokens.textTertiary }
        if isTodayCell { return tokens.primary }
        if isForcedWorkday { return tokens.textPrimary }
        return day.isWorkday ? tokens.textPrimary : tokens.weekend
    }

    private var lunarColor: Color {
        guard day.isCurrentMonth else { return tokens.textTertiary.opacity(0.7) }
        if isTodayCell { return tokens.primary }
        if isDeclaredRestDay { return tokens.primaryDeep }
        return tokens.textSecondary
    }

    private var backgroundColor: Color {
        if isInSelection { return tokens.selectionBackground }
        guard day.isCurrentMonth else { return .clear }
        if isTodayCell { return tokens.primaryLight }
        return isDeclaredRestDay ? tokens.primaryLight : .clear
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)

            if isSelectionStart || isSelectionEnd {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tokens.selectionBorder, lineWidth: 2)
            }

            VStack(spacing: 2) {
                Text("\(day.solarDay)")
                    .font(.system(size: solarSize, weight: .semibold))
                    .foregroundColor(solarColor)
                if let text = day.lunarText {
                    Text(text)
                        .font(.system(size: lunarSize, weight: .regular))
                        .foregroundColor(lunarColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.top, badgeText != nil ? 8 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let badge = badgeText {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(badgeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(2)
            }
        }
        .opacity(day.isCurrentMonth ? 1.0 : 0.5)
        .contentShape(Rectangle())
    }

    /// 今天优先标"今"；其余只有法定节假日/自定义休息日才标"休"，
    /// 普通周末不标注；调休工作日/自定义工作日标"班"。
    private var badgeText: String? {
        if isTodayCell { return "今" }
        if isForcedWorkday { return "班" }
        if isDeclaredRestDay { return "休" }
        return nil
    }

    private var badgeColor: Color {
        if isTodayCell { return tokens.primary }
        return isForcedWorkday ? tokens.workdayTag : tokens.holidayTag
    }
}
