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
            let spec = CarouselSpec.compute(stageWidth: geo.size.width, stageHeight: geo.size.height)
            let index = selectedIndex

            ZStack(alignment: .bottom) {
                background(size: geo.size)

                ForEach(Array(games.enumerated()), id: \.element.id) { itemIndex, game in
                    let offset = itemIndex - index
                    if abs(offset) <= spec.maxOffset {
                        CarouselCover(
                            game: game,
                            isSelected: offset == 0,
                            width: spec.baseWidth,
                            height: spec.baseHeight
                        )
                        .scaleEffect(spec.scale(for: offset))
                        .offset(
                            x: spec.position(for: offset),
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

    @ViewBuilder private func background(size: CGSize) -> some View {
        if let game = library.selectedGame {
            GameCoverView(title: game.title, engine: game.engine, coverPath: game.coverPath)
                .frame(width: size.width, height: size.height)
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

    private func opacity(for offset: Int) -> Double {
        offset == 0 ? 1 : max(0.35, 0.85 - 0.18 * Double(abs(offset) - 1))
    }
}

private struct CarouselSpec {
    let baseWidth: CGFloat
    let baseHeight: CGFloat
    let maxOffset: Int
    private let scales: [CGFloat]
    private let positions: [CGFloat]

    static func compute(stageWidth: CGFloat, stageHeight: CGFloat) -> CarouselSpec {
        let gap: CGFloat = 14
        let available = max(stageWidth - 40, 360)
        let heightCap = min(stageHeight * 0.62, 430)

        func scale(_ offset: Int) -> CGFloat {
            offset == 0 ? 1 : max(0.55, 0.85 - 0.12 * CGFloat(offset - 1))
        }
        func factor(_ k: Int) -> CGFloat {
            var value = scale(k)
            for i in 1...k {
                value += scale(i - 1) + scale(i)
            }
            return value
        }

        var chosen = 1
        var width: CGFloat = 0
        for k in [3, 2, 1] {
            let candidate = (available - CGFloat(k) * 2 * gap) / factor(k)
            if candidate >= 180 {
                chosen = k
                width = candidate
                break
            }
        }
        if width == 0 {
            width = (available - 2 * gap) / factor(1)
        }
        width = min(max(width, 140), min(320, heightCap * 0.75))

        var scales: [CGFloat] = []
        var positions: [CGFloat] = []
        var accumulated: CGFloat = 0
        for i in 0...chosen {
            let current = scale(i)
            scales.append(current)
            if i > 0 {
                accumulated += (scales[i - 1] + current) / 2 * width + gap
            }
            positions.append(accumulated)
        }

        return CarouselSpec(
            baseWidth: width,
            baseHeight: width / 0.75,
            maxOffset: chosen,
            scales: scales,
            positions: positions
        )
    }

    func scale(for offset: Int) -> CGFloat {
        scales[min(abs(offset), maxOffset)]
    }

    func position(for offset: Int) -> CGFloat {
        let distance = positions[min(abs(offset), maxOffset)]
        return offset < 0 ? -distance : distance
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
