import AppKit
import SwiftUI

@main
struct ZaloThemeSwitcherApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(\.themePalette, appState.palette)
                .preferredColorScheme(appState.palette.preferredScheme)
                .onAppear { appState.bootstrap() }
                .onReceive(
                    DistributedNotificationCenter.default.publisher(
                        for: Notification.Name("AppleInterfaceThemeChangedNotification")
                    )
                ) { _ in
                    if appState.isSystemThemeSelected {
                        appState.refreshPalette()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 740, height: 660)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
