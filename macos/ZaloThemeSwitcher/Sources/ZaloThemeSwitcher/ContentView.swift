import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.themePalette) private var palette

    private var selectedTheme: ThemeDefinition? {
        state.selectedTheme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsPanel
            tipBanner
            if state.showLogs {
                logPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .frame(minWidth: 700, idealWidth: 740, minHeight: 600, idealHeight: 660)
        .background(palette.panel)
        .animation(.easeInOut(duration: 0.2), value: state.selectedThemeID)
        .task {
            if state.themes.isEmpty {
                state.bootstrap()
            }
            await state.refreshStatus()
        }
        .sheet(isPresented: $state.showThemePicker) {
            ThemePickerSheet()
                .environmentObject(state)
                .environment(\.themePalette, state.palette)
        }
        .sheet(isPresented: $state.showFontPicker) {
            FontPickerSheet()
                .environmentObject(state)
                .environment(\.themePalette, state.palette)
        }
    }

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            headerRow
            thinDivider
            SettingsRow(title: "Accent") {
                TrailingControls {
                    TextPill(text: state.isSystemThemeSelected ? "System" : (selectedTheme?.mode.capitalized ?? "—"))
                    if let theme = selectedTheme {
                        ColorPill(hex: theme.accentHex, color: theme.accentColor)
                    } else {
                        ColorPill(hex: "SYSTEM", color: palette.accent)
                    }
                }
            }
            thinDivider
            SettingsRow(title: "Background") {
                TrailingControls {
                    if let theme = selectedTheme {
                        ColorPill(hex: theme.backgroundHex, color: theme.backgroundColor)
                    } else {
                        ColorPill(hex: "SYSTEM", color: palette.panel)
                    }
                }
            }
            thinDivider
            SettingsRow(title: "Foreground") {
                TrailingControls {
                    if let theme = selectedTheme {
                        ColorPill(hex: theme.foregroundHex, color: theme.foregroundColor)
                    } else {
                        ColorPill(hex: "SYSTEM", color: palette.foreground)
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
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.muted)
                    }
                }
                .buttonStyle(.plain)
                .disabled(state.isBusy)
            }
            thinDivider
            SettingsRow(title: "Font size") {
                HStack(spacing: 8) {
                    Button {
                        state.bumpFontSize(by: -AppState.fontSizeStepPercent)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(palette.foreground)
                            .frame(width: 28, height: AppDesign.pillHeight)
                            .background(PillBackground())
                    }
                    .buttonStyle(.plain)
                    .disabled(state.isBusy || state.selectedFontSizePercent <= AppState.fontSizeMinPercent)

                    Slider(
                        value: Binding(
                            get: { Double(state.selectedFontSizePercent) },
                            set: { state.selectedFontSizePercent = AppState.clampFontSize(Int($0.rounded())) }
                        ),
                        in: Double(AppState.fontSizeMinPercent)...Double(AppState.fontSizeMaxPercent),
                        step: Double(AppState.fontSizeStepPercent)
                    )
                    .tint(palette.accent)
                    .disabled(state.isBusy)

                    Button {
                        state.bumpFontSize(by: AppState.fontSizeStepPercent)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(palette.foreground)
                            .frame(width: 28, height: AppDesign.pillHeight)
                            .background(PillBackground())
                    }
                    .buttonStyle(.plain)
                    .disabled(state.isBusy || state.selectedFontSizePercent >= AppState.fontSizeMaxPercent)

                    Text("\(state.selectedFontSizePercent)%")
                        .font(AppDesign.mono(12, weight: .semibold))
                        .foregroundStyle(palette.foreground)
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
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
                .fill(palette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.corner, style: .continuous)
                        .strokeBorder(palette.panelLine, lineWidth: 1)
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
            AppLogoImage(size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.headerTitle)
                    .font(AppDesign.mono(14, weight: .semibold))
                    .foregroundStyle(palette.foreground)
                    .lineLimit(1)
                Text(state.headerSubtitle)
                    .font(AppDesign.mono(11))
                    .foregroundStyle(palette.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Refresh") {
                Task { await state.refreshStatus() }
            }
            .buttonStyle(.plain)
            .font(AppDesign.mono(12, weight: .medium))
            .foregroundStyle(palette.muted)
            .frame(height: AppDesign.pillHeight)
            .disabled(state.isBusy)

            Button("Restore") {
                Task { await state.restoreOriginal() }
            }
            .buttonStyle(.plain)
            .font(AppDesign.mono(12, weight: .medium))
            .foregroundStyle(palette.muted)
            .frame(height: AppDesign.pillHeight)
            .disabled(state.isBusy || !state.status.hasBackup)

            Button {
                state.showThemePicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Themes")
                        .font(AppDesign.mono(12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(palette.foreground)
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
                        .foregroundStyle(palette.danger)
                        .lineLimit(2)
                } else if state.isSystemThemeSelected {
                    Text("Pick a theme to preview it here, then Apply to Zalo")
                        .font(AppDesign.mono(11))
                        .foregroundStyle(palette.muted)
                        .lineLimit(1)
                } else {
                    Text(state.status.zaloExists
                          ? "Ready · \(state.fontFamilies.count) system fonts · native installer"
                          : "Zalo not found")
                        .font(AppDesign.mono(11))
                        .foregroundStyle(palette.muted)
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
                        .fill(palette.accent.opacity(state.isSystemThemeSelected ? 0.45 : 1))
                )
            }
            .buttonStyle(.plain)
            .disabled(state.isBusy || !state.status.zaloExists || selectedTheme == nil)
        }
        .frame(height: AppDesign.rowHeight)
        .padding(.horizontal, AppDesign.horizontalInset)
    }

    private var tipBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.accent)
                .padding(.top, 1)
            Text("Please use the default Light theme in the Zalo app for correct color rendering.")
                .font(AppDesign.mono(12, weight: .medium))
                .foregroundStyle(palette.foreground)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.panelSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(palette.panelLine, lineWidth: 1)
                )
        )
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Installer log")
                    .font(AppDesign.mono(12, weight: .semibold))
                    .foregroundStyle(palette.muted)
                Spacer()
                if !state.logText.isEmpty {
                    Button("Clear") { state.clearLog() }
                        .buttonStyle(.plain)
                        .font(AppDesign.mono(11, weight: .medium))
                        .foregroundStyle(palette.muted)
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    Text(state.logText.isEmpty
                          ? "Please use the default Light theme in the Zalo app for correct color rendering.\n\nInstaller output will appear here…"
                          : state.logText)
                        .font(AppDesign.mono(11))
                        .foregroundStyle(palette.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .id("log-top")
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(palette.panelSoft)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(palette.panelLine, lineWidth: 1)
                        )
                )
                .onAppear { proxy.scrollTo("log-top", anchor: .top) }
                .onChange(of: state.logText) { _, _ in
                    proxy.scrollTo("log-top", anchor: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(palette.panelLine.opacity(0.85))
            .frame(height: 1)
            .padding(.horizontal, AppDesign.horizontalInset)
    }
}

struct ThemePickerSheet: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.themePalette) private var palette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Themes")
                    .font(AppDesign.mono(14, weight: .semibold))
                    .foregroundStyle(palette.foreground)
                Text("\(state.filteredThemes.count)/\(state.themes.count)")
                    .font(AppDesign.mono(11))
                    .foregroundStyle(palette.muted)
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
                    .foregroundStyle(palette.accent)
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

            Divider().overlay(palette.panelLine)

            List {
                Button {
                    state.selectSystemTheme()
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(Color(nsColor: .controlAccentColor), lineWidth: 2)
                            )
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Default")
                                .font(AppDesign.mono(13, weight: .medium))
                                .foregroundStyle(palette.foreground)
                            Text("Follow macOS Light / Dark")
                                .font(AppDesign.mono(11))
                                .foregroundStyle(palette.muted)
                        }
                        Spacer()
                        if state.isSystemThemeSelected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(palette.accent)
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(palette.panel)

                ForEach(state.filteredThemes) { theme in
                    Button {
                        state.selectTheme(id: theme.id)
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
                                    .foregroundStyle(palette.foreground)
                                Text(theme.subtitle)
                                    .font(AppDesign.mono(11))
                                    .foregroundStyle(palette.muted)
                            }
                            Spacer()
                            ColorPill(hex: theme.accentHex, color: theme.accentColor)
                            if theme.id == state.selectedThemeID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(palette.accent)
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(palette.panel)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 560, height: 520)
        .background(palette.panel)
    }
}

struct FontPickerSheet: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.themePalette) private var palette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("System fonts")
                    .font(AppDesign.mono(14, weight: .semibold))
                    .foregroundStyle(palette.foreground)
                Text("\(state.filteredFonts.count)/\(state.fontFamilies.count)")
                    .font(AppDesign.mono(11))
                    .foregroundStyle(palette.muted)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .font(AppDesign.mono(12, weight: .medium))
                    .foregroundStyle(palette.accent)
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
                                    .foregroundStyle(state.selectedFontWeight == weight.weight ? .white : palette.foreground)
                                    .padding(.horizontal, 10)
                                    .frame(height: 26)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(state.selectedFontWeight == weight.weight ? palette.accent : palette.panelSoft)
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
                .foregroundStyle(palette.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider().overlay(palette.panelLine)

            List(state.filteredFonts) { family in
                Button {
                    state.selectedFontFamily = family.name
                    state.syncWeightForSelectedFont()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(family.name)
                                .font(.custom(family.name, size: 14))
                                .foregroundStyle(palette.foreground)
                            Text("\(family.weights.count) weight\(family.weights.count == 1 ? "" : "s")")
                                .font(AppDesign.mono(11))
                                .foregroundStyle(palette.muted)
                        }
                        Spacer()
                        if family.name == state.selectedFontFamily {
                            Image(systemName: "checkmark")
                                .foregroundStyle(palette.accent)
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(palette.panel)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 560, height: 560)
        .background(palette.panel)
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
