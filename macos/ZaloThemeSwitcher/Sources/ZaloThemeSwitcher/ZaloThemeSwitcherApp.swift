import SwiftUI

@main
struct ZaloThemeSwitcherApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
                .onAppear { appState.bootstrap() }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 740, height: 660)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
