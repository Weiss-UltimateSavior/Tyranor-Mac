import SwiftUI

struct GameCoverView: View {
    let title: String
    let engine: EngineKind

    var body: some View {
        ZStack {
            LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 160, height: 160)
                .blur(radius: 42)
                .offset(x: -55, y: -65)

            Circle()
                .fill(Color.black.opacity(0.28))
                .frame(width: 200, height: 200)
                .blur(radius: 52)
                .offset(x: 62, y: 92)

            VStack(spacing: 8) {
                Spacer()
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
                    .padding(.horizontal, 10)
                Text(engine.rawValue)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
            .padding(12)
        }
    }

    private var palette: [Color] {
        CoverPalette.palette(for: title)
    }
}

private enum CoverPalette {
    static let all: [[Color]] = [
        [Color(red: 0.36, green: 0.42, blue: 0.86), Color(red: 0.76, green: 0.44, blue: 0.85)],
        [Color(red: 0.16, green: 0.55, blue: 0.76), Color(red: 0.24, green: 0.24, blue: 0.54)],
        [Color(red: 0.86, green: 0.45, blue: 0.36), Color(red: 0.54, green: 0.25, blue: 0.46)],
        [Color(red: 0.25, green: 0.66, blue: 0.55), Color(red: 0.15, green: 0.35, blue: 0.52)],
        [Color(red: 0.76, green: 0.56, blue: 0.36), Color(red: 0.50, green: 0.30, blue: 0.52)],
        [Color(red: 0.50, green: 0.36, blue: 0.76), Color(red: 0.24, green: 0.20, blue: 0.42)],
        [Color(red: 0.85, green: 0.60, blue: 0.70), Color(red: 0.40, green: 0.50, blue: 0.82)],
    ]

    static func palette(for title: String) -> [Color] {
        let index = title.utf8.reduce(0) { ($0 + Int($1)) % all.count }
        return all[index]
    }
}
