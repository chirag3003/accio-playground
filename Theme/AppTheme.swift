import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.18, green: 1.0, blue: 0.45)
    static let warning = Color(red: 0.98, green: 0.78, blue: 0.35)

    static let textPrimary = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let textSecondary = Color(red: 0.72, green: 0.76, blue: 0.80)

    static let surface = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let surfaceElevated = Color(red: 0.16, green: 0.17, blue: 0.21)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.07, blue: 0.09),
            Color(red: 0.10, green: 0.11, blue: 0.14),
            Color(red: 0.08, green: 0.10, blue: 0.13)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
