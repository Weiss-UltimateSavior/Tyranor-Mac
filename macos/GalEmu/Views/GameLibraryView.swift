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
        ScrollView {
            if library.visibleGames.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                    ForEach(library.visibleGames) { game in
                        GameCard(
                            game: game,
                            isSelected: game.id == library.selectedGameID,
                            onSelect: { library.select(game) },
                            onLaunch: {
                                library.select(game)
                                emulator.launch(game)
                            }
                        )
                    }
                }
                .padding(26)
            }
        }
        .background(Theme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 30))
            Text("没有符合条件的游戏")
                .font(.system(size: 13))
        }
        .foregroundStyle(Theme.textTertiary)
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }
}

private struct GameCard: View {
    let game: Game
    let isSelected: Bool
    let onSelect: () -> Void
    let onLaunch: () -> Void

    @EnvironmentObject private var appearance: AppearanceSettings
    @State private var isHovering = false

    private var coverRadius: CGFloat {
        appearance.coverCorner.radius
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GameCoverView(title: game.title, engine: game.engine)
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
        .onTapGesture(count: 2) { onLaunch() }
        .onTapGesture { onSelect() }
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
