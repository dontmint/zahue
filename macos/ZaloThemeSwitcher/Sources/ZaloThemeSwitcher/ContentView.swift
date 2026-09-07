import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            statusCard
            themeList
            actions
            tips
            logs
        }
        .padding(20)
        .background(Color(hex: 0xFAF4ED).opacity(0.35))
        .task { await state.refreshStatus() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Zalo Theme Switcher")
                .font(.title2.weight(.semibold))
            Text("Maple Font + Rosé Pine themes for Zalo PC")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
    }

    private var statusCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                labeled("Zalo", state.status.zaloExists ? state.zaloPath : "Not found at \(state.zaloPath)")
                labeled("Current theme", state.currentThemeName)
                labeled("Backup", state.status.hasBackup ? "app.asar.bak present" : "No backup yet")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var themeList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Themes")
                .font(.headline)
            ForEach(state.themes) { theme in
                ThemeRow(theme: theme, selected: state.selectedThemeID == theme.id)
                    .onTapGesture {
                        state.selectedThemeID = theme.id
                    }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                Task { await state.applySelectedTheme() }
            } label: {
                if state.isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }
                Text("Apply Theme")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x286983))
            .disabled(state.isBusy || !state.status.zaloExists)

            Button("Restore Original") {
                Task { await state.restoreOriginal() }
            }
            .disabled(state.isBusy || !state.status.hasBackup)

            Spacer()

            Button("Refresh") {
                Task { await state.refreshStatus() }
            }
            .disabled(state.isBusy)
        }
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Grant App Management to this app (or Terminal) in System Settings → Privacy & Security.", systemImage: "lock.shield")
            Label("Install Maple Mono in Font Book for the intended look.", systemImage: "textformat")
            Label("For Dawn, set Zalo appearance to Light. Re-apply after Zalo updates.", systemImage: "info.circle")
            if let err = state.lastError {
                Text(err)
                    .foregroundStyle(Color(hex: 0xB4637A))
                    .font(.callout)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var logs: some View {
        DisclosureGroup(isExpanded: $state.showLogs) {
            ScrollView {
                Text(state.logText.isEmpty ? "Installer output will appear here…" : state.logText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 120, maxHeight: 180)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.05)))
        } label: {
            Text("Installer log")
                .font(.headline)
        }
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .font(.callout)
    }
}

private struct ThemeRow: View {
    let theme: ThemeDefinition
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(Array(theme.swatches.enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.name)
                    .font(.body.weight(.medium))
                Text("\(theme.subtitle) · \(theme.mode)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: 0x286983))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selected ? Color(hex: 0x286983).opacity(0.12) : Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(selected ? Color(hex: 0x286983).opacity(0.45) : Color.black.opacity(0.06), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}
