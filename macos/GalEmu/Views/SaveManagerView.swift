import SwiftUI

struct SaveManagerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("存档管理")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("完成") { dismiss() }
                    .buttonStyle(SecondaryActionButtonStyle())
            }
            .padding(20)

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            VStack(spacing: 10) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 28))
                Text("暂无存档")
                    .font(.system(size: 13))
            }
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 560, height: 420)
        .background(Theme.background)
    }
}
