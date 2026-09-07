import AppKit
import SwiftUI

enum AppDesign {
    // Everforest-inspired chrome for the switcher UI itself
    static let panel = Color(hex: 0xFDF6E3)
    static let panelSoft = Color(hex: 0xF4EFDA)
    static let panelLine = Color(hex: 0xE6E1CC)
    static let accent = Color(hex: 0x93B259)
    static let foreground = Color(hex: 0x5C6A72)
    static let muted = Color(hex: 0x829181)
    static let danger = Color(hex: 0xF85552)

    static let corner: CGFloat = 16
    static let rowHeight: CGFloat = 40
    static let labelWidth: CGFloat = 108
    static let pillHeight: CGFloat = 30
    static let horizontalInset: CGFloat = 16

    static func mono(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        let candidates = [
            "Maple Mono NF",
            "MapleMono-NF-Regular",
            "Maple Mono",
            "MapleMono-Regular"
        ]
        for name in candidates {
            if NSFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
        }
        return .system(size: size, weight: weight, design: .monospaced)
    }
}

struct PillBackground: View {
    var fill: Color = AppDesign.panelSoft
    var stroke: Color = AppDesign.panelLine

    var body: some View {
        Capsule(style: .continuous)
            .fill(fill)
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(stroke.opacity(0.95), lineWidth: 1)
            )
    }
}

struct SettingsRow<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(AppDesign.mono(13, weight: .medium))
                .foregroundStyle(AppDesign.foreground)
                .frame(width: AppDesign.labelWidth, alignment: .leading)

            Spacer(minLength: 8)

            trailing()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: AppDesign.rowHeight)
        .padding(.horizontal, AppDesign.horizontalInset)
    }
}

struct ColorPill: View {
    let hex: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(hex.uppercased())
                .font(AppDesign.mono(12, weight: .medium))
                .foregroundStyle(AppDesign.foreground)
                .monospacedDigit()
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(Circle().strokeBorder(AppDesign.panelLine, lineWidth: 1))
        }
        .padding(.horizontal, 12)
        .frame(height: AppDesign.pillHeight)
        .background(PillBackground())
    }
}

struct TextPill: View {
    let text: String
    var emphasized: Bool = false

    var body: some View {
        Text(text)
            .font(AppDesign.mono(12, weight: emphasized ? .semibold : .medium))
            .foregroundStyle(emphasized ? Color.white : AppDesign.foreground)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: AppDesign.pillHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(emphasized ? AppDesign.accent : AppDesign.panelSoft)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(emphasized ? AppDesign.accent : AppDesign.panelLine, lineWidth: 1)
                    )
            )
    }
}

struct TrailingControls<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
