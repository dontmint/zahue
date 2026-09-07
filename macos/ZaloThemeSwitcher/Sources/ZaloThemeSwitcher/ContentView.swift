import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    private var selectedTheme: ThemeDefinition? {
        state.selectedTheme
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
        .frame(minWidth: 700, idealWidth: 740, minHeight: 600, idealHeight: 660)
        .background(AppDesign.panel)
        .task {
            if state.themes.isEmpty {
                state.bootstrap()
            }
            await state.refreshStatus()
        }
        .sheet(isPresented: $state.showThemePicker) {
            ThemePickerSheet()
                .environmentObject(state)
        }
        .sheet(isPresented: $state.showFontPicker) {
            FontPickerSheet()
                .environmentObject(state)
        }
    }

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            headerRow
            thinDivider
            SettingsRow(title: "Accent") {
                TrailingControls {
                    TextPill(text: selectedTheme?.mode.capitalized ?? "—")
                    if let theme = selectedTheme {
                        ColorPill(hex: theme.accentHex, color: theme.accentColor)
                    }
                }
            }
            thinDivider
            SettingsRow(title: "Background") {
                TrailingControls {
                    if let theme = selectedTheme {
                        ColorPill(hex: theme.backgroundHex, color: theme.backgroundColor)
                    }
                }
            }
            thinDivider
            SettingsRow(title: "Foreground") {
                TrailingControls {
                    if let theme = selectedTheme {
                        ColorPill(hex: theme.foregroundHex, color: theme.foregroundColor)
                    }
                }
            }
            thinDivider
            SettingsRow(title: "UI font") {
                Button {
                    state.showFontPicker = true
                } label: {
                    TrailingControls {
                        TextPill(text: state.selectedFontFamily)
                        TextPill(text: weightLabel)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AppDesign.muted)
                    }
                }
                .buttonStyle(.plain)
                .disabled(state.isBusy)
            }
            thinDivider
            SettingsRow(title: "Status") {
                TrailingControls {
                    TextPill(text: state.currentThemeName)
                    TextPill(text: "\(state.themes.count) themes")
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

    private var weightLabel: String {
        if let match = state.availableWeights.first(where: { $0.weight == state.selectedFontWeight }) {
            return match.name
        }
        return String(state.selectedFontWeight)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedTheme?.name ?? "Select a theme")
                    .font(AppDesign.mono(14, weight: .semibold))
                    .foregroundStyle(AppDesign.foreground)
                    .lineLimit(1)
                Text(selectedTheme.map { "\($0.family) · \($0.mode) · terminalcolors.com" } ?? "\(state.themes.count) themes available")
                    .font(AppDesign.mono(11))
                    .foregroundStyle(AppDesign.muted)
                    .lineLimit(1)
            }
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

            Button {
                state.showThemePicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Themes")
                        .font(AppDesign.mono(12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(AppDesign.foreground)
                .padding(.horizontal, 12)
                .frame(height: AppDesign.pillHeight)
                .background(PillBackground())
            }
            .buttonStyle(.plain)
            .disabled(state.isBusy)
        }
        .frame(minHeight: AppDesign.rowHeight)
        .padding(.vertical, 6)
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
                    Text(state.status.zaloExists
                          ? "Ready · \(state.fontFamilies.count) system fonts"
                          : "Zalo not found")
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
            .disabled(state.isBusy || !state.status.zaloExists || selectedTheme == nil)
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

struct ThemePickerSheet: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Themes")
                    .font(AppDesign.mono(14, weight: .semibold))
                    .foregroundStyle(AppDesign.foreground)
                Text("\(state.filteredThemes.count)/\(state.themes.count)")
                    .font(AppDesign.mono(11))
                    .foregroundStyle(AppDesign.muted)
                Spacer()
                Picker("Mode", selection: $state.themeFilter) {
                    ForEach(ThemeModeFilter.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .font(AppDesign.mono(12, weight: .medium))
                    .foregroundStyle(AppDesign.accent)
            }
            .padding(16)

            TextField("Search themes…", text: $state.themeQuery)
                .textFieldStyle(.plain)
                .font(AppDesign.mono(13))
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(PillBackground())
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider().overlay(AppDesign.panelLine)

            List(state.filteredThemes) { theme in
                Button {
                    state.selectedThemeID = theme.id
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(theme.accentColor, lineWidth: 2)
                            )
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.name)
                                .font(AppDesign.mono(13, weight: .medium))
                                .foregroundStyle(AppDesign.foreground)
                            Text(theme.subtitle)
                                .font(AppDesign.mono(11))
                                .foregroundStyle(AppDesign.muted)
                        }
                        Spacer()
                        ColorPill(hex: theme.accentHex, color: theme.accentColor)
                        if theme.id == state.selectedThemeID {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppDesign.accent)
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(AppDesign.panel)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 560, height: 520)
        .background(AppDesign.panel)
    }
}

struct FontPickerSheet: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("System fonts")
                    .font(AppDesign.mono(14, weight: .semibold))
                    .foregroundStyle(AppDesign.foreground)
                Text("\(state.filteredFonts.count)/\(state.fontFamilies.count)")
                    .font(AppDesign.mono(11))
                    .foregroundStyle(AppDesign.muted)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .font(AppDesign.mono(12, weight: .medium))
                    .foregroundStyle(AppDesign.accent)
            }
            .padding(16)

            TextField("Search fonts…", text: $state.fontQuery)
                .textFieldStyle(.plain)
                .font(AppDesign.mono(13))
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(PillBackground())
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            if !state.availableWeights.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(state.availableWeights) { weight in
                            Button {
                                state.selectedFontWeight = weight.weight
                            } label: {
                                Text(weight.name)
                                    .font(AppDesign.mono(11, weight: .medium))
                                    .foregroundStyle(state.selectedFontWeight == weight.weight ? .white : AppDesign.foreground)
                                    .padding(.horizontal, 10)
                                    .frame(height: 26)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(state.selectedFontWeight == weight.weight ? AppDesign.accent : AppDesign.panelSoft)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)
            }

            Text("Preview — The quick brown fox jumps over 123")
                .font(.custom(state.selectedFontFamily, size: 16))
                .fontWeight(Font.Weight(css: state.selectedFontWeight))
                .foregroundStyle(AppDesign.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider().overlay(AppDesign.panelLine)

            List(state.filteredFonts) { family in
                Button {
                    state.selectedFontFamily = family.name
                    state.syncWeightForSelectedFont()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(family.name)
                                .font(.custom(family.name, size: 14))
                                .foregroundStyle(AppDesign.foreground)
                            Text("\(family.weights.count) weight\(family.weights.count == 1 ? "" : "s")")
                                .font(AppDesign.mono(11))
                                .foregroundStyle(AppDesign.muted)
                        }
                        Spacer()
                        if family.name == state.selectedFontFamily {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppDesign.accent)
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(AppDesign.panel)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 560, height: 560)
        .background(AppDesign.panel)
    }
}

private extension Font.Weight {
    init(css: Int) {
        switch css {
        case ...100: self = .ultraLight
        case 200: self = .thin
        case 300: self = .light
        case 400: self = .regular
        case 500: self = .medium
        case 600: self = .semibold
        case 700: self = .bold
        case 800: self = .heavy
        default: self = .black
        }
    }
}
