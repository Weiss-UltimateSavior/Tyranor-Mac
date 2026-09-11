import SwiftUI

struct GameLibraryView: View {
    @EnvironmentObject private var library: GameLibraryController
    @EnvironmentObject private var emulator: EmulatorController
    @EnvironmentObject private var appearance: AppearanceSettings

    private var columns: [GridItem] {
        let width = appearance.coverSize.columnWidth
        return [GridItem(.adaptive(minimum: width.min, maximum: width.max), spacing: 20)]
    }

    var body: some View {
        VStack(spacing: 0) {
            if library.filter == .all {
                searchBar
            }
            Group {
                if library.visibleGames.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                            ForEach(library.visibleGames) { game in
                                GameCard(
                                    game: game,
                                    isSelected: game.id == library.selectedGameID,
                                    onSelect: { library.select(game) },
                                    onLaunch: {
                                        library.select(game)
                                        library.markPlayed(game)
                                        emulator.launch(game)
                                    }
                                )
                            }
                        }
                        .padding(26)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
            TextField("搜索游戏", text: $library.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !library.searchText.isEmpty {
                Button {
                    library.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 26)
        .padding(.top, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: library.games.isEmpty ? "square.grid.2x2" : "tray")
                .font(.system(size: 30))
            Text(library.games.isEmpty ? "游戏库为空" : "没有符合条件的游戏")
                .font(.system(size: 13))
            if library.games.isEmpty {
                Text("点击左侧「游戏扫描」添加游戏")
                    .font(.system(size: 12))
            }
        }
        .foregroundStyle(Theme.textTertiary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GameCard: View {
    let game: Game
    let isSelected: Bool
    let onSelect: () -> Void
    let onLaunch: () -> Void

    @EnvironmentObject private var appearance: AppearanceSettings
    @State private var isHovering = false
    @State private var lastTapTime = Date.distantPast

    private var coverRadius: CGFloat {
        appearance.coverCorner.radius
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GameCoverView(title: game.title, engine: game.engine, coverPath: game.coverPath)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: coverRadius, style: .continuous))
                .overlay(alignment: .topTrailing) { favoriteBadge }
                .overlay {
                    RoundedRectangle(cornerRadius: coverRadius, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.35), lineWidth: 1)
                }

            Text(game.title)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 2)
        }
        .padding(8)
        .background(
            isSelected ? Theme.card : Color.clear,
            in: RoundedRectangle(cornerRadius: coverRadius + 4, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: coverRadius + 4, style: .continuous)
                .strokeBorder(isSelected ? appearance.accent.color : Color.clear, lineWidth: 2)
        }
        .shadow(color: isSelected ? appearance.accent.color.opacity(0.45) : .clear, radius: 14)
        .scaleEffect(isHovering && !isSelected ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture {
            let now = Date()
            if now.timeIntervalSince(lastTapTime) < 0.35 {
                lastTapTime = .distantPast
                onLaunch()
            } else {
                lastTapTime = now
                onSelect()
            }
        }
    }

    @ViewBuilder private var favoriteBadge: some View {
        if game.isFavorite {
            HStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 9, weight: .bold))
                Text("收藏")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(Theme.favorite)
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(.black.opacity(0.55), in: Capsule())
            .padding(8)
        }
    }
}
