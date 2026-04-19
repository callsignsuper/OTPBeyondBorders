import Foundation

/// Role + surface colors for OTP Beyond Borders.
/// Hex values are **approximate** pending sampling of the official Etihad poster PDF (CLAUDE.md §Palette).
/// Swap these before GA; call sites depend only on the keys, not the hex.
public struct Palette: Sendable {
    public let creamBackground: RGB
    public let etihadGold:      RGB
    public let darkTeal:        RGB
    public let terracotta:      RGB
    public let navy:            RGB

    public static let approximate = Palette(
        creamBackground: .hex(0xF7F2E9),
        etihadGold:      .hex(0xB8935A),
        darkTeal:        .hex(0x2E4A57),
        terracotta:      .hex(0xD56A4A),
        navy:            .hex(0x1F2E3D)
    )

    public func color(for role: Role) -> RGB {
        switch role {
        case .pilots:   return navy
        case .cabin:    return etihadGold
        case .ground:   return terracotta
        case .engineer: return darkTeal
        }
    }

    public struct RGB: Sendable, Hashable {
        public let red: Double
        public let green: Double
        public let blue: Double
        public let alpha: Double

        public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }

        public static func hex(_ value: UInt32, alpha: Double = 1.0) -> RGB {
            RGB(
                red:   Double((value >> 16) & 0xFF) / 255.0,
                green: Double((value >> 8)  & 0xFF) / 255.0,
                blue:  Double( value        & 0xFF) / 255.0,
                alpha: alpha
            )
        }
    }
}
