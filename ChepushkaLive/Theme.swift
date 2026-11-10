import SwiftUI

struct AppTheme {
    static let background = Color(hex: "#0A1011")
    static let backgroundRadial = Color(hex: "#18332D")
    static let accent = Color(hex: "#CAFA75")
    static let accentDark = Color(hex: "#132018")
    static let surface = Color(hex: "#1B2825")
    static let surfaceAlt = Color(hex: "#152420")
    static let surfaceCard = Color(hex: "#121C1B")
    static let textPrimary = Color(hex: "#F5F8F6")
    static let textSecondary = Color(hex: "#A5B3AF")
    static let border = Color(hex: "#25352F")
    static let danger = Color(hex: "#FF6B6B")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
