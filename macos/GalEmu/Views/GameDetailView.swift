import AppKit
import SwiftUI

struct GameDetailView: View {
    @EnvironmentObject private var library: GameLibraryController
    @EnvironmentObject private var emulator: EmulatorController
    @EnvironmentObject private var appearance: AppearanceSettings

    @State private var showDetailSheet = false
    @State private var showSaveManager = false
    @State private var showMoreOptions = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Theme.separator)
            content
        }
        .frame(height: 156)
        .background(Theme.panel)
        .sheet(isPresented: $showDetailSheet) {
            if let game = library.selectedGame {
                GameDetailSheet(game: game)
            }
        }
        .sheet(isPresented: $showSaveManager) {
            SaveManagerView()
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
                Text(game.metadata.summary)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
                    .lineLimit(2)
                    .frame(maxWidth: 700, alignment: .leading)
            }

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                Button {
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
            }
            .padding(6)
            .frame(width: 170)
        }
    }

    private func metadataLine(for game: Game) -> String {
        var parts: [String] = [
            game.metadata.developer,
            "\(game.metadata.releaseYear)",
            game.engine.rawValue,
        ]
        if game.playtimeHours > 0 {
            parts.append("\(Int(game.playtimeHours)) 小时")
        }
        parts.append(game.status.rawValue)
        return parts.joined(separator: " · ")
    }
}

private struct GameDetailSheet: View {
    let game: Game

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 22) {
                GameCoverView(title: game.title, engine: game.engine)
                    .frame(width: 190, height: 253)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text(game.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(metadataLine)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textSecondary)

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

                    Text(game.metadata.summary)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

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
        .frame(width: 620, height: 320, alignment: .topLeading)
        .background(Theme.background)
    }

    private var metadataLine: String {
        var parts: [String] = [
            game.metadata.developer,
            "\(game.metadata.releaseYear)",
            game.engine.rawValue,
        ]
        if game.playtimeHours > 0 {
            parts.append("\(Int(game.playtimeHours)) 小时")
        }
        parts.append(game.status.rawValue)
        return parts.joined(separator: " · ")
    }
}

private struct MoreOptionRow: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
