import SwiftUI

struct ContentView: View {
    @StateObject private var emulator = EmulatorController()
    @EnvironmentObject private var library: GameLibraryController
    @EnvironmentObject private var appearance: AppearanceSettings

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SidebarView()
                Divider()
                    .overlay(Theme.separator)
                VStack(spacing: 0) {
                    switch library.selection {
                    case .home:
                        HomeView()
                    case let .engine(engine):
                        EngineSettingsView(engine: engine)
                    case .library:
                        GameLibraryView()
                        GameDetailView()
                    }
                }
            }
            .background(Theme.background)

            if let notice = emulator.notice {
                EmulatorView(game: notice.game, statusMessage: notice.message) {
                    emulator.dismissNotice()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .environmentObject(emulator)
        .frame(minWidth: 1100, minHeight: 700)
        .preferredColorScheme(appearance.themeMode.colorScheme)
    }
}
