import SwiftUI

struct MonthCalendarView: View {
    @EnvironmentObject var viewModel: CalendarSelectionViewModel
    @EnvironmentObject var settings: SettingsStore

    let monthDate: Date
    let tokens: ThemeTokens
    let compact: Bool

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }

    private var days: [CalendarDay] {
        viewModel.gridBuilder.buildGrid(for: monthDate)
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        f.calendar = calendar
        return f.string(from: monthDate)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(monthTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tokens.textSecondary)

            WeekdayHeaderView(tokens: tokens, weekStart: settings.weekStart)

            GeometryReader { geo in
                let columns = 7
                let rows = 6
                let cellWidth = geo.size.width / CGFloat(columns)
                let cellHeight = geo.size.height / CGFloat(rows)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: columns), spacing: 0) {
                    ForEach(days) { day in
                        CalendarDayCell(
                            day: day,
                            tokens: tokens,
                            isSelectionStart: isStart(day),
                            isSelectionEnd: isEnd(day),
                            isInSelection: isInRange(day),
                            compact: compact
                        )
                        .frame(height: cellHeight)
                        .onTapGesture {
                            viewModel.handleClick(day.date)
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 4, coordinateSpace: .local)
                        .onChanged { value in
                            guard let day = day(at: value.location, cellWidth: cellWidth, cellHeight: cellHeight) else { return }
                            if !viewModel.isDragging {
                                viewModel.handleDragStart(day.date)
                            } else {
                                viewModel.handleDragUpdate(day.date)
                            }
                        }
                        .onEnded { _ in
                            viewModel.handleDragEnd()
                        }
                )
            }
            .frame(height: compact ? 260 : 320)
        }
    }

    private func day(at point: CGPoint, cellWidth: CGFloat, cellHeight: CGFloat) -> CalendarDay? {
        guard cellWidth > 0, cellHeight > 0 else { return nil }
        let col = min(max(Int(point.x / cellWidth), 0), 6)
        let row = min(max(Int(point.y / cellHeight), 0), 5)
        let index = row * 7 + col
        guard index >= 0, index < days.count else { return nil }
        return days[index]
    }

    private func isStart(_ day: CalendarDay) -> Bool {
        guard let selection = viewModel.selection else { return false }
        return calendar.isDate(day.date, inSameDayAs: selection.normalized.startDate)
    }

    private func isEnd(_ day: CalendarDay) -> Bool {
        guard let selection = viewModel.selection else { return false }
        return calendar.isDate(day.date, inSameDayAs: selection.normalized.endDate)
    }

    private func isInRange(_ day: CalendarDay) -> Bool {
        guard let selection = viewModel.selection else { return false }
        let normalized = selection.normalized
        return day.date >= calendar.startOfDay(for: normalized.startDate) && day.date <= calendar.startOfDay(for: normalized.endDate)
    }
}
