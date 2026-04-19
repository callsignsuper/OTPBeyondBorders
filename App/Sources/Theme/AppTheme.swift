import SwiftUI
import OTPKit

extension Palette.RGB {
    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension Color {
    static var otpCream:      Color { Palette.approximate.creamBackground.swiftUIColor }
    static var otpGold:       Color { Palette.approximate.etihadGold.swiftUIColor }
    static var otpTeal:       Color { Palette.approximate.darkTeal.swiftUIColor }
    static var otpTerracotta: Color { Palette.approximate.terracotta.swiftUIColor }
    static var otpNavy:       Color { Palette.approximate.navy.swiftUIColor }

    static func role(_ r: Role) -> Color { Palette.approximate.color(for: r).swiftUIColor }
}
