import AppKit
import SwiftUI

enum AppDesign {
    static let corner: CGFloat = 16
    static let rowHeight: CGFloat = 44
    static let labelWidth: CGFloat = 120
    static let pillHeight: CGFloat = 34
    static let horizontalInset: CGFloat = 16

    static func mono(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        let adjusted = size + 2
        let candidates = [
            "Maple Mono NF",
            "MapleMono-NF-Regular",
            "Maple Mono",
            "MapleMono-Regular"
        ]
        for name in candidates {
            if NSFont(name: name, size: adjusted) != nil {
                return .custom(name, size: adjusted)
            }
        }
        return .system(size: adjusted, weight: weight, design: .monospaced)
    }
}

struct PillBackground: View {
    @Environment(\.themePalette) private var palette
    var emphasized: Bool = false

    var body: some View {
        Capsule(style: .continuous)
            .fill(emphasized ? palette.accent : palette.panelSoft)
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder((emphasized ? palette.accent : palette.panelLine).opacity(0.95), lineWidth: 1)
            )
    }
}

struct SettingsRow<Trailing: View>: View {
    @Environment(\.themePalette) private var palette
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(AppDesign.mono(13, weight: .medium))
                .foregroundStyle(palette.foreground)
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
    @Environment(\.themePalette) private var palette
    let hex: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(hex.uppercased())
                .font(AppDesign.mono(12, weight: .medium))
                .foregroundStyle(palette.foreground)
                .monospacedDigit()
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(Circle().strokeBorder(palette.panelLine, lineWidth: 1))
        }
        .padding(.horizontal, 12)
        .frame(height: AppDesign.pillHeight)
        .background(PillBackground())
    }
}

struct TextPill: View {
    @Environment(\.themePalette) private var palette
    let text: String
    var emphasized: Bool = false

    var body: some View {
        Text(text)
            .font(AppDesign.mono(12, weight: emphasized ? .semibold : .medium))
            .foregroundStyle(emphasized ? Color.white : palette.foreground)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: AppDesign.pillHeight)
            .background(PillBackground(emphasized: emphasized))
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

struct AppLogoImage: View {
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let image = Self.loadLogo() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color.black)
                    .frame(width: size, height: size)
                    .overlay(
                        Text("Z")
                            .font(.system(size: size * 0.48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    )
            }
        }
    }

    private static func loadLogo() -> NSImage? {
        let candidates = [
            Bundle.main.url(forResource: "AppLogo", withExtension: "png"),
            Bundle.main.resourceURL?.appendingPathComponent("AppLogo.png")
        ].compactMap { $0 }
        for url in candidates {
            if let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
    }
}
