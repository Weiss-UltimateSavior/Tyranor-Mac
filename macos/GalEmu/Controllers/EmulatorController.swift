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

        guard game.engine == .kirikiri else {
            notice = Notice(
                game: game,
                message: "暂未接入 \(game.engine.rawValue) 内核，当前仅支持 KIRIKIRI（krkrsdl3）"
            )
            return
        }

        guard let executable = CoreLocator.krkrsdl3Executable() else {
            notice = Notice(game: game, message: "未找到 krkrsdl3 内核，请在设置 → 内核中配置路径")
            return
        }

        let gameDirectory = URL(fileURLWithPath: game.metadata.directoryPath)
        let process = Process()
        process.executableURL = executable
        process.arguments = [EngineDetector.kirikiriLaunchEntry(in: gameDirectory).path]
        var environment = ProcessInfo.processInfo.environment
        environment["KRKR_WINDOW_TITLE"] = game.title
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
