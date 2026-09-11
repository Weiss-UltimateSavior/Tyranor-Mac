import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        applyAppIdentity()
        DispatchQueue.main.async { [weak self] in
            self?.applyAppIdentity()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func applyAppIdentity() {
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }

        guard let appMenuItem = NSApp.mainMenu?.item(at: 0) else { return }
        appMenuItem.title = "Tyranor Mac"
        if let submenu = appMenuItem.submenu, let aboutItem = submenu.item(at: 0) {
            aboutItem.title = "关于 Tyranor Mac"
        }
    }
}
