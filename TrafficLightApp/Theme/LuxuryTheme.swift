import SwiftUI

enum LuxuryTheme {
    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.03, green: 0.05, blue: 0.08), Color(red: 0.08, green: 0.11, blue: 0.16)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.16), Color.white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(red: 0.35, green: 0.75, blue: 1.0)
}
