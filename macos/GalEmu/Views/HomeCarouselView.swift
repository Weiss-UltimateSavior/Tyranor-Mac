import SwiftUI

struct HomeCarouselView: View {
    @EnvironmentObject private var library: GameLibraryController
    @EnvironmentObject private var appearance: AppearanceSettings

    var body: some View {
        VStack(spacing: 0) {
            stage
            GameDetailView()
        }
        .background(Color.black)
    }

    private var games: [Game] {
        library.visibleGames
    }

    private var selectedIndex: Int {
        games.firstIndex { $0.id == library.selectedGameID } ?? 0
    }

    private var stage: some View {
        GeometryReader { geo in
            let baseHeight = min(geo.size.height * 0.56, 420)
            let baseWidth = baseHeight * 0.75
            let step = baseWidth * 0.72
            let index = selectedIndex

            ZStack(alignment: .bottom) {
                if let game = library.selectedGame {
                    GameCoverView(title: game.title, engine: game.engine, coverPath: game.coverPath)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: appearance.homeBlurEnabled ? 55 : 0, opaque: true)
                        .clipped()
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.25), value: game.id)

                    LinearGradient(
                        colors: [Color.black.opacity(0.72), Color.black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                } else {
                    Color.black
                }

                ForEach(Array(games.enumerated()), id: \.element.id) { itemIndex, game in
                    let offset = itemIndex - index
                    if abs(offset) <= 3 {
                        CarouselCover(
                            game: game,
                            isSelected: offset == 0,
                            width: baseWidth,
                            height: baseHeight
                        )
                        .scaleEffect(scale(for: offset))
                        .offset(
                            x: CGFloat(offset) * step,
                            y: offset == 0 ? 0 : -CGFloat(abs(offset)) * 8
                        )
                        .opacity(opacity(for: offset))
                        .zIndex(offset == 0 ? 10 : Double(6 - abs(offset)))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                library.select(game)
                            }
                        }
                    }
                }

                caption
                    .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }

    @ViewBuilder private var caption: some View {
        if let game = library.selectedGame {
            HStack(spacing: 8) {
                if !game.metadata.developer.isEmpty, game.metadata.developer != "未知" {
                    Text(game.metadata.developer)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("-")
                        .foregroundStyle(.white.opacity(0.35))
                }
                Text(game.title)
                    .foregroundStyle(.white)
            }
            .font(.system(size: 15, weight: .medium))
            .lineLimit(1)
            .shadow(color: .black.opacity(0.6), radius: 8)
            .animation(.easeInOut(duration: 0.2), value: game.id)
        }
    }

    private func scale(for offset: Int) -> CGFloat {
        offset == 0 ? 1 : max(0.55, 0.86 - 0.13 * CGFloat(abs(offset) - 1))
    }

    private func opacity(for offset: Int) -> Double {
        offset == 0 ? 1 : max(0.35, 0.85 - 0.18 * Double(abs(offset) - 1))
    }
}

private struct CarouselCover: View {
    let game: Game
    let isSelected: Bool
    let width: CGFloat
    let height: CGFloat

    @EnvironmentObject private var appearance: AppearanceSettings

    private var coverRadius: CGFloat {
        appearance.coverCorner.radius
    }

    var body: some View {
        VStack(spacing: 0) {
            cover
            reflection
        }
        .shadow(color: .black.opacity(isSelected ? 0.55 : 0.3), radius: isSelected ? 24 : 10, y: isSelected ? 14 : 8)
        .contentShape(Rectangle())
    }

    private var cover: some View {
        GameCoverView(title: game.title, engine: game.engine, coverPath: game.coverPath)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: coverRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: coverRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(isSelected ? 0.16 : 0.05), lineWidth: 1)
            }
    }

    private var reflection: some View {
        GameCoverView(title: game.title, engine: game.engine, coverPath: game.coverPath)
            .frame(width: width, height: height)
            .scaleEffect(x: 1, y: -1)
            .frame(width: width, height: height * 0.45, alignment: .top)
            .clipped()
            .opacity(0.22)
            .mask(
                LinearGradient(
                    colors: [.white.opacity(0.85), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
