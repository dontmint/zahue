import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    private var selectedTheme: ThemeDefinition {
        state.selectedTheme ?? ThemeDefinition.all[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsPanel

            if state.showLogs {
                logPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .frame(minWidth: 640, idealWidth: 680, minHeight: 560, idealHeight: 620)
        .background(AppDesign.panel)
        .task { await state.refreshStatus() }
    }

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            headerRow
            thinDivider
            SettingsRow(title: "Accent") {
                TrailingControls {
                    TextPill(text: "Custom")
                    ColorPill(hex: selectedTheme.accentHex, color: selectedTheme.accent)
                }
            }
            thinDivider
            SettingsRow(title: "Background") {
                TrailingControls {
                    ColorPill(hex: selectedTheme.backgroundHex, color: selectedTheme.background)
                }
            }
            thinDivider
            SettingsRow(title: "Foreground") {
                TrailingControls {
                    ColorPill(hex: selectedTheme.foregroundHex, color: selectedTheme.foreground)
                }
            }
            thinDivider
            SettingsRow(title: "UI font") {
                TrailingControls {
                    TextPill(text: "Maple Mono NF")
                    TextPill(text: "SemiBold")
                }
            }
            thinDivider
            SettingsRow(title: "Status") {
                TrailingControls {
                    TextPill(text: state.currentThemeName)
                    TextPill(text: state.status.hasBackup ? "Backup OK" : "No backup")
                }
            }
            thinDivider
            actionRow
        }
        .background(
            RoundedRectangle(cornerRadius: AppDesign.corner, style: .continuous)
                .fill(AppDesign.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.corner, style: .continuous)
                        .strokeBorder(AppDesign.panelLine, lineWidth: 1)
                )
        )
        .fixedSize(horizontal: false, vertical: true)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(selectedTheme.mode)
                .font(AppDesign.mono(14, weight: .semibold))
                .foregroundStyle(AppDesign.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Refresh") {
                Task { await state.refreshStatus() }
            }
            .buttonStyle(.plain)
            .font(AppDesign.mono(12, weight: .medium))
            .foregroundStyle(AppDesign.muted)
            .frame(height: AppDesign.pillHeight)
            .disabled(state.isBusy)

            Button("Restore") {
                Task { await state.restoreOriginal() }
            }
            .buttonStyle(.plain)
            .font(AppDesign.mono(12, weight: .medium))
            .foregroundStyle(AppDesign.muted)
            .frame(height: AppDesign.pillHeight)
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
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(AppDesign.foreground)
                .padding(.horizontal, 12)
                .frame(height: AppDesign.pillHeight)
                .background(PillBackground())
            }
            .menuStyle(.borderlessButton)
            .disabled(state.isBusy)
        }
        .frame(height: AppDesign.rowHeight)
        .padding(.horizontal, AppDesign.horizontalInset)
    }

    private var actionRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Group {
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
                .frame(height: AppDesign.pillHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppDesign.accent)
                )
            }
            .buttonStyle(.plain)
            .disabled(state.isBusy || !state.status.zaloExists)
        }
        .frame(height: AppDesign.rowHeight)
        .padding(.horizontal, AppDesign.horizontalInset)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppDesign.panelSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppDesign.panelLine, lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(AppDesign.panelLine.opacity(0.85))
            .frame(height: 1)
            .padding(.horizontal, AppDesign.horizontalInset)
    }
}
