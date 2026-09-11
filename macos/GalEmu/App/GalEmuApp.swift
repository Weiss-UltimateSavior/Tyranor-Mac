import SwiftUI

@main
struct GalEmuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var library = GameLibraryController()
    @StateObject private var settings = EmulatorSettings()
    @StateObject private var appearance = AppearanceSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .environmentObject(settings)
                .environmentObject(appearance)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1360, height: 860)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(appearance)
        }
    }
}
