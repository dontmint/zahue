import SwiftUI

@main
struct ZaloThemeSwitcherApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 680, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
