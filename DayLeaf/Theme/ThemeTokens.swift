import SwiftUI

struct ThemeTokens {
    let primary: Color
    let primaryDeep: Color
    let primaryLight: Color
    let primarySoft: Color
    let background: Color
    let panelBackground: Color
    let toolbarBackground: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let weekend: Color
    let holidayTag: Color
    let workdayTag: Color
    let selectionBackground: Color
    let selectionBorder: Color
    let shadow: Color
    let showsCat: Bool

    static let fresh = ThemeTokens(
        primary: Color(hex: "2F9D5B"),
        primaryDeep: Color(hex: "168A45"),
        primaryLight: Color(hex: "EAF8F0"),
        primarySoft: Color(hex: "F4FBF7"),
        background: Color(hex: "FBFFFC"),
        panelBackground: Color(hex: "FFFFFF"),
        toolbarBackground: Color(hex: "F3FBF6"),
        border: Color(hex: "CFE8D8"),
        textPrimary: Color(hex: "2D2F33"),
        textSecondary: Color(hex: "4B5563"),
        textTertiary: Color(hex: "9CA3AF"),
        weekend: Color(hex: "168A45"),
        holidayTag: Color(hex: "1E8E3E"),
        workdayTag: Color(hex: "526078"),
        selectionBackground: Color(hex: "EAF8F0"),
        selectionBorder: Color(hex: "168A45"),
        shadow: Color.black.opacity(0.14),
        showsCat: false
    )

    static let cute = ThemeTokens(
        primary: Color(hex: "F04F7A"),
        primaryDeep: Color(hex: "D83F68"),
        primaryLight: Color(hex: "FFF0F5"),
        primarySoft: Color(hex: "FFF7FA"),
        background: Color(hex: "FFFBFD"),
        panelBackground: Color(hex: "FFFFFF"),
        toolbarBackground: Color(hex: "FFF2F6"),
        border: Color(hex: "F6CEDB"),
        textPrimary: Color(hex: "2D2F33"),
        textSecondary: Color(hex: "5F6368"),
        textTertiary: Color(hex: "B9BDC5"),
        weekend: Color(hex: "EF3D61"),
        holidayTag: Color(hex: "F04F7A"),
        workdayTag: Color(hex: "526078"),
        selectionBackground: Color(hex: "FFF0F5"),
        selectionBorder: Color(hex: "F04F7A"),
        shadow: Color.black.opacity(0.14),
        showsCat: true
    )

    static func tokens(for theme: AppTheme, colorScheme: ColorScheme) -> ThemeTokens {
        switch theme {
        case .fresh:
            return .fresh
        case .cute:
            return .cute
        case .system:
            return colorScheme == .dark ? .fresh : .fresh
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
