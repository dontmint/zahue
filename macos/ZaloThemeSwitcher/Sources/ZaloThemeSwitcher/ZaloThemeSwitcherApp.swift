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
        .defaultSize(width: 640, height: 460)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
