import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    private var selectedTheme: ThemeDefinition {
        state.selectedTheme ?? ThemeDefinition.all[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            settingsPanel
                .padding(18)

            if state.showLogs {
                logPanel
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
            }
        }
        .frame(minWidth: 560, idealWidth: 620, minHeight: 420)
        .background(AppDesign.panel)
        .task { await state.refreshStatus() }
    }

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            headerRow
            thinDivider
            SettingsRow(title: "Accent") {
                HStack(spacing: 8) {
                    TextPill(text: "Custom")
                    ColorPill(hex: selectedTheme.accentHex, color: selectedTheme.accent)
                }
            }
            thinDivider
            SettingsRow(title: "Background") {
                ColorPill(hex: selectedTheme.backgroundHex, color: selectedTheme.background)
            }
            thinDivider
            SettingsRow(title: "Foreground") {
                ColorPill(hex: selectedTheme.foregroundHex, color: selectedTheme.foreground)
            }
            thinDivider
            SettingsRow(title: "UI font") {
                HStack(spacing: 8) {
                    TextPill(text: "Maple Mono NF")
                    TextPill(text: "SemiBold")
                }
            }
            thinDivider
            SettingsRow(title: "Status") {
                HStack(spacing: 8) {
                    TextPill(text: state.currentThemeName)
                    TextPill(text: state.status.hasBackup ? "Backup OK" : "No backup")
                }
            }
            thinDivider
            actionRow
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppDesign.corner, style: .continuous)
                .fill(AppDesign.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.corner, style: .continuous)
                        .strokeBorder(AppDesign.panelLine, lineWidth: 1)
                )
        )
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            Text(selectedTheme.mode)
                .font(AppDesign.mono(14, weight: .semibold))
                .foregroundStyle(AppDesign.foreground)

            Spacer()

            Button("Refresh") {
                Task { await state.refreshStatus() }
            }
            .buttonStyle(.plain)
            .font(AppDesign.mono(12, weight: .medium))
            .foregroundStyle(AppDesign.muted)
            .disabled(state.isBusy)

            Button("Restore") {
                Task { await state.restoreOriginal() }
            }
            .buttonStyle(.plain)
            .font(AppDesign.mono(12, weight: .medium))
            .foregroundStyle(AppDesign.muted)
            .disabled(state.isBusy || !state.status.hasBackup)

            Menu {
                ForEach(state.themes) { theme in
                    Button(theme.name) {
                        state.selectedThemeID = theme.id
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "textformat")
                        .font(.system(size: 11, weight: .semibold))
                    Text(selectedTheme.name)
                        .font(AppDesign.mono(12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(AppDesign.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(PillBackground())
            }
            .menuStyle(.borderlessButton)
            .disabled(state.isBusy)
        }
        .frame(minHeight: AppDesign.rowHeight)
        .padding(.horizontal, 4)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            if let err = state.lastError {
                Text(err)
                    .font(AppDesign.mono(11))
                    .foregroundStyle(AppDesign.danger)
                    .lineLimit(2)
            } else {
                Text(state.status.zaloExists ? "Ready for \(state.zaloPath)" : "Zalo not found")
                    .font(AppDesign.mono(11))
                    .foregroundStyle(AppDesign.muted)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                state.showLogs.toggle()
            } label: {
                TextPill(text: state.showLogs ? "Hide log" : "Show log")
            }
            .buttonStyle(.plain)

            Button {
                Task { await state.applySelectedTheme() }
            } label: {
                HStack(spacing: 6) {
                    if state.isBusy {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    Text(state.isBusy ? "Working…" : "Apply theme")
                        .font(AppDesign.mono(12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppDesign.accent)
                )
            }
            .buttonStyle(.plain)
            .disabled(state.isBusy || !state.status.zaloExists)
        }
        .frame(minHeight: AppDesign.rowHeight)
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Installer log")
                .font(AppDesign.mono(12, weight: .semibold))
                .foregroundStyle(AppDesign.muted)

            ScrollView {
                Text(state.logText.isEmpty ? "Installer output will appear here…" : state.logText)
                    .font(AppDesign.mono(11))
                    .foregroundStyle(AppDesign.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(12)
            .frame(minHeight: 120, maxHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppDesign.panelSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppDesign.panelLine, lineWidth: 1)
                    )
            )
        }
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(AppDesign.panelLine.opacity(0.85))
            .frame(height: 1)
            .padding(.horizontal, 4)
    }
}
