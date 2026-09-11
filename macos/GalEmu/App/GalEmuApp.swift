import SwiftUI

@main
struct TyranorMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var library = GameLibraryController()
    @StateObject private var settings = EmulatorSettings()
    @StateObject private var appearance = AppearanceSettings()
    @StateObject private var krSettings = KREngineSettings()
    @StateObject private var onsSettings = ONSEngineSettings()
    @StateObject private var coverSettings = CoverSettings()
    @StateObject private var coverScraper = CoverScraper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .environmentObject(settings)
                .environmentObject(appearance)
                .environmentObject(krSettings)
                .environmentObject(onsSettings)
                .environmentObject(coverSettings)
                .environmentObject(coverScraper)
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
