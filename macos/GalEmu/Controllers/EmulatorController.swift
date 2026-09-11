import Combine
import Foundation

final class EmulatorController: ObservableObject {
    struct Notice: Identifiable {
        let id = UUID()
        let game: Game
        let message: String
    }

    @Published private(set) var notice: Notice?
    @Published private(set) var isProcessRunning = false

    private var process: Process?

    func launch(_ game: Game) {
        guard !isProcessRunning else { return }
        notice = nil

        let gameDirectory = URL(fileURLWithPath: game.metadata.directoryPath)
        let executable: URL
        let arguments: [String]

        switch game.engine {
        case .kirikiri:
            guard let url = CoreLocator.krkrsdl3Executable() else {
                notice = Notice(game: game, message: "未找到 krkrsdl3 内核，请在设置 → 内核中配置路径")
                return
            }
            executable = url
            arguments = [EngineDetector.kirikiriLaunchEntry(in: gameDirectory).path]
                + KREngineSettings.persistedLaunchArguments()
        case .ons:
            guard let url = CoreLocator.onsyuriExecutable() else {
                notice = Notice(game: game, message: "未找到 OnscripterYuri 内核，请在设置 → 内核中配置路径")
                return
            }
            let saveDirectory = gameDirectory.appendingPathComponent("save", isDirectory: true)
            try? FileManager.default.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
            executable = url
            arguments = ["-r", gameDirectory.path, "--save-dir", saveDirectory.path + "/"]
                + ONSEngineSettings.persistedLaunchArguments()
        case .artemis:
            notice = Notice(game: game, message: "暂未接入 \(game.engine.rawValue) 内核，当前支持 KIRIKIRI 与 ONS")
            return
        }

        let process = Process()
        process.executableURL = executable
        process.currentDirectoryURL = gameDirectory
        process.arguments = arguments
        var environment = ProcessInfo.processInfo.environment
        environment["KRKR_WINDOW_TITLE"] = game.title
        environment["ONS_WINDOW_TITLE"] = game.title
        process.environment = environment
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.process = nil
                self?.isProcessRunning = false
            }
        }

        do {
            try process.run()
            self.process = process
            isProcessRunning = true
        } catch {
            notice = Notice(game: game, message: "启动失败：\(error.localizedDescription)")
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        isProcessRunning = false
        notice = nil
    }

    func dismissNotice() {
        notice = nil
    }
}
