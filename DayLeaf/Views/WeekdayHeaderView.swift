import SwiftUI

struct WeekdayHeaderView: View {
    let tokens: ThemeTokens
    let weekStart: WeekStartDay

    private var labels: [String] {
        let all = ["日", "一", "二", "三", "四", "五", "六"]
        if weekStart == .sunday {
            return all
        }
        return Array(all[1...]) + [all[0]]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isWeekend(index) ? tokens.weekend : tokens.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 36)
    }

    private func isWeekend(_ index: Int) -> Bool {
        if weekStart == .sunday {
            return index == 0 || index == 6
        }
        return index == 5 || index == 6
    }
}
