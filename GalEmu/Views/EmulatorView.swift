import SwiftUI

struct EmulatorView: View {
    let game: Game
    let statusMessage: String?
    let onStop: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(game.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                Text(statusMessage ?? "\(game.engine.rawValue) 模拟器内核尚未接入")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.6))
                Button {
                    onStop()
                } label: {
                    Label("关闭", systemImage: "xmark")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.top, 8)
            }
        }
        .onExitCommand(perform: onStop)
    }
}
