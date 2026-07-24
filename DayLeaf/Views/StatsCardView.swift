import SwiftUI

struct StatsCardView: View {
    let icon: String
    let title: String
    let value: Int
    let tokens: ThemeTokens

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(tokens.primaryDeep)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(tokens.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(value))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(tokens.textPrimary)
                Text("天")
                    .font(.system(size: 11))
                    .foregroundColor(tokens.textSecondary)
            }
        }
        .padding(10)
        .frame(minWidth: 64, idealWidth: 88, maxWidth: 100, minHeight: 72, maxHeight: 72, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(tokens.primarySoft))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tokens.border, lineWidth: 1))
    }
}
