import SwiftUI

struct QuickSelectBar: View {
    @EnvironmentObject var viewModel: CalendarSelectionViewModel
    let tokens: ThemeTokens

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickSelectOption.allCases) { option in
                    Button(option.displayName) {
                        viewModel.applyQuickSelect(option)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(tokens.textSecondary)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(RoundedRectangle(cornerRadius: 7).fill(tokens.primarySoft))
                }
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 36)
    }
}
