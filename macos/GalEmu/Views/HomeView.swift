import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var library: GameLibraryController
    @EnvironmentObject private var appearance: AppearanceSettings

    var body: some View {
        Group {
            if let game = library.selectedGame {
                switch appearance.homeStyle {
                case .hero:
                    content(for: game)
                case .carousel:
                    HomeCarouselView()
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .ignoresSafeArea(edges: .top)
    }

    private func content(for game: Game) -> some View {
        VStack(spacing: 0) {
            hero(for: game)
            coverRow
            GameDetailView()
        }
    }

    private func hero(for game: Game) -> some View {
        ZStack(alignment: .bottomLeading) {
            GameCoverView(title: game.title, engine: game.engine, coverPath: game.coverPath)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: appearance.homeBlurEnabled ? 55 : 0, opaque: true)
                .allowsHitTesting(false)

            LinearGradient(
                colors: [Color.black.opacity(0.45), Color.black.opacity(0.08)],
                startPoint: .bottom,
                endPoint: .top
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                Text(game.title)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 2)
                    .lineLimit(2)
                Text(metadataLine(for: game))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                if !game.metadata.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(game.metadata.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var coverRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("游戏")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(library.visibleGames) { game in
                        HomeCoverCard(
                            game: game,
                            isSelected: game.id == library.selectedGameID,
                            onSelect: { library.select(game) }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 162)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Theme.panel)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "house")
                .font(.system(size: 30))
            Text("游戏库为空")
                .font(.system(size: 13))
            Text("点击左侧「游戏扫描」添加游戏")
                .font(.system(size: 12))
        }
        .foregroundStyle(Theme.textTertiary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

private struct HomeCoverCard: View {
    let game: Game
    let isSelected: Bool
    let onSelect: () -> Void

    @EnvironmentObject private var appearance: AppearanceSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GameCoverView(title: game.title, engine: game.engine, coverPath: game.coverPath)
                .frame(width: 104, height: 139)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            isSelected ? appearance.accent.color : Color.black.opacity(0.25),
                            lineWidth: isSelected ? 2 : 1
                        )
                }
            Text(game.title)
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .lineLimit(1)
                .frame(width: 104, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
