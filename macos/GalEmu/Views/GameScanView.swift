import AppKit
import SwiftUI

struct GameScanView: View {
    @EnvironmentObject private var library: GameLibraryController
    @Environment(\.dismiss) private var dismiss

    @State private var directory: URL?
    @State private var isScanning = false
    @State private var hasScanned = false
    @State private var progress: Double = 0
    @State private var results: [Game] = []
    @State private var recentRoots: [URL] = []

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .overlay(Theme.separator)
            content
            Divider()
                .overlay(Theme.separator)
            footer
        }
        .frame(width: 580, height: 460)
        .background(Theme.background)
        .onAppear {
            recentRoots = ScanRootStore.load()
            if directory == nil {
                directory = recentRoots.first
            }
        }
    }

    private var header: some View {
        HStack {
            Text("游戏扫描")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button("完成") { dismiss() }
                .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding(20)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            directoryRow

            if results.isEmpty && !isScanning && !recentRoots.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("最近目录")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 10)
                    ForEach(recentRoots.prefix(4), id: \.self) { root in
                        RecentRootRow(root: root, isSelected: root == directory) {
                            selectRoot(root)
                        }
                    }
                }
            }

            if isScanning {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                    Text("正在扫描… \(Int(progress * 100))%")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            if !results.isEmpty {
                Text("发现 \(results.count) 款游戏")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(results) { game in
                            ScanResultRow(game: game)
                        }
                    }
                }
            } else if hasScanned && !isScanning {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 26))
                    Text("未发现可识别的游戏目录")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var directoryRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            Text(directory?.path ?? "未选择游戏目录")
                .font(.system(size: 12.5))
                .foregroundStyle(directory == nil ? Theme.textTertiary : Theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            Button("选择目录") { chooseDirectory() }
                .buttonStyle(SecondaryActionButtonStyle())
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text("支持 KIRIKIRI / ARTEMIS / ONS 目录识别")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            Button("开始扫描") { startScan() }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(directory == nil || isScanning)
            Button("添加到游戏库") { addResults() }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(results.isEmpty)
        }
        .padding(20)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        panel.message = "选择包含游戏的文件夹"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        selectRoot(url)
    }

    private func selectRoot(_ root: URL) {
        directory = root
        results = []
        hasScanned = false
        progress = 0
    }

    private func startScan() {
        guard let directory else { return }
        isScanning = true
        hasScanned = false
        results = []
        progress = 0
        Task {
            for step in 1...20 {
                try? await Task.sleep(for: .milliseconds(35))
                progress = Double(step) / 20
            }
            let found = await Task.detached(priority: .userInitiated) {
                EngineDetector.scanGames(in: directory)
            }.value
            results = found
            hasScanned = true
            isScanning = false
        }
    }

    private func addResults() {
        guard !results.isEmpty else { return }
        if let directory {
            ScanRootStore.add(directory)
        }
        library.add(results)
        dismiss()
    }
}

private struct ScanResultRow: View {
    let game: Game

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(game.title)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(game.metadata.directoryPath)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Text(game.engine.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.card, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct RecentRootRow: View {
    let root: URL
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11))
                    .frame(width: 14)
                Text(root.path)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isHovering ? Theme.hover : Color.clear,
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
