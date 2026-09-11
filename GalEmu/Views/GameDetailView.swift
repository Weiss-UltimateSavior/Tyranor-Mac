import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct GameDetailView: View {
    @EnvironmentObject private var library: GameLibraryController
    @EnvironmentObject private var emulator: EmulatorController
    @EnvironmentObject private var appearance: AppearanceSettings

    @State private var showDetailSheet = false
    @State private var showSaveManager = false
    @State private var showMoreOptions = false
    @State private var showDeleteConfirm = false
    @State private var showPatchBrowser = false
    @State private var showCoverPicker = false
    @State private var showRename = false
    @State private var renameText = ""

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
            content
        }
        .frame(height: 156, alignment: .top)
        .background(Theme.panel)
        .sheet(isPresented: $showDetailSheet) {
            if let game = library.selectedGame {
                GameDetailSheet(game: game)
            }
        }
        .sheet(isPresented: $showSaveManager) {
            if let game = library.selectedGame {
                SaveManagerView(game: game)
            }
        }
        .sheet(isPresented: $showPatchBrowser) {
            if let game = library.selectedGame {
                PatchBrowserView(game: game)
            }
        }
        .sheet(isPresented: $showCoverPicker) {
            if let game = library.selectedGame {
                CoverPickerView(game: game)
            }
        }
        .alert("重命名游戏", isPresented: $showRename) {
            TextField("游戏名称", text: $renameText)
            Button("保存") {
                if let game = library.selectedGame {
                    library.rename(game, to: renameText)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("只修改应用内显示的名称，不会改动游戏文件。")
        }
        .confirmationDialog(
            "确定从游戏库中删除「\(library.selectedGame?.title ?? "")」吗？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let game = library.selectedGame {
                    library.remove(game)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("只删除应用中的数据，不会删除真实游戏文件。")
        }
    }

    @ViewBuilder private var content: some View {
        if let game = library.selectedGame {
            detail(for: game)
        } else {
            Text("选择一款游戏以查看详情")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func detail(for game: Game) -> some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(game.title)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(metadataLine(for: game))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Text(game.metadata.summary.isEmpty ? game.metadata.directoryPath : game.metadata.summary)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
                    .lineLimit(2)
                    .frame(maxWidth: 700, alignment: .leading)
            }

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                Button {
                    library.markPlayed(game)
                    emulator.launch(game)
                } label: {
                    Label("启动", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryActionButtonStyle(color: appearance.accent.color))

                Button {
                    library.toggleFavorite(game)
                } label: {
                    Label(game.isFavorite ? "已收藏" : "收藏", systemImage: "heart.fill")
                }
                .buttonStyle(SecondaryActionButtonStyle(tint: game.isFavorite ? Theme.favorite : nil))

                Button {
                    showDetailSheet = true
                } label: {
                    Label("详情", systemImage: "info.circle")
                }
                .buttonStyle(SecondaryActionButtonStyle())

                moreButton(for: game)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }

    private func moreButton(for game: Game) -> some View {
        Button {
            showMoreOptions.toggle()
        } label: {
            Label("更多", systemImage: "ellipsis")
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .popover(isPresented: $showMoreOptions, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 2) {
                MoreOptionRow(title: "获取封面", icon: "photo.on.rectangle.angled") {
                    showMoreOptions = false
                    showCoverPicker = true
                }
                MoreOptionRow(title: "选择本地图片…", icon: "photo") {
                    showMoreOptions = false
                    chooseCover(for: game)
                }
                MoreOptionRow(title: "重命名", icon: "pencil") {
                    showMoreOptions = false
                    renameText = game.title
                    showRename = true
                }
                if game.engine == .kirikiri {
                    MoreOptionRow(title: "在线补丁", icon: "arrow.down.circle") {
                        showMoreOptions = false
                        showPatchBrowser = true
                    }
                }
                MoreOptionRow(title: "存档管理", icon: "externaldrive") {
                    showMoreOptions = false
                    showSaveManager = true
                }
                MoreOptionRow(title: "打开游戏目录", icon: "folder") {
                    showMoreOptions = false
                    NSWorkspace.shared.open(URL(fileURLWithPath: game.metadata.directoryPath))
                }
                MoreOptionRow(title: "在访达中显示", icon: "magnifyingglass") {
                    showMoreOptions = false
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: game.metadata.directoryPath)])
                }
                Divider()
                    .overlay(Theme.separator)
                    .padding(.vertical, 4)
                MoreOptionRow(title: "删除游戏", icon: "trash", isDestructive: true) {
                    showMoreOptions = false
                    showDeleteConfirm = true
                }
            }
            .padding(6)
            .frame(width: 170)
        }
    }

    private func chooseCover(for game: Game) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.prompt = "选择"
        panel.message = "选择封面图片"
        if panel.runModal() == .OK, let url = panel.url,
           let path = CoverImageCache.saveCustomCover(from: url, gameID: game.id) {
            library.setCover(for: game.id, path: path, source: .custom)
        }
    }

    private func metadataLine(for game: Game) -> String {
        var parts: [String] = []
        if !game.metadata.developer.isEmpty, game.metadata.developer != "未知" {
            parts.append(game.metadata.developer)
        }
        parts.append(game.engine.rawValue)
        return parts.joined(separator: " · ")
    }
}

private struct GameDetailSheet: View {
    let game: Game

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 22) {
                GameCoverView(title: game.title, engine: game.engine, coverPath: game.coverPath)
                    .frame(width: 190, height: 253)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text(game.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if let originalTitle = game.metadata.originalTitle,
                       !originalTitle.isEmpty,
                       originalTitle != game.title {
                        Text(originalTitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                    Text(metadataLine)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textSecondary)
                    if let source = game.coverSource {
                        Text("封面来源：\(source.displayName)")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    if !game.metadata.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(game.metadata.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Theme.card, in: Capsule())
                            }
                        }
                    }

                    if !game.metadata.summary.isEmpty {
                        Text(game.metadata.summary)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(4)
                            .lineLimit(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(game.metadata.directoryPath)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("关闭") { dismiss() }
                    .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding(24)
        .frame(width: 640, height: 360, alignment: .topLeading)
        .background(Theme.background)
    }

    private var metadataLine: String {
        var parts: [String] = []
        if !game.metadata.developer.isEmpty, game.metadata.developer != "未知" {
            parts.append(game.metadata.developer)
        }
        if let releaseDate = game.metadata.releaseDate, !releaseDate.isEmpty {
            parts.append(releaseDate)
        } else if game.metadata.releaseYear > 0 {
            parts.append("\(game.metadata.releaseYear)")
        }
        parts.append(game.engine.rawValue)
        return parts.joined(separator: " · ")
    }
}

private struct MoreOptionRow: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(.system(size: 13))
                Spacer(minLength: 0)
            }
            .foregroundStyle(isDestructive ? Theme.favorite : Theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
