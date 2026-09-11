import SwiftUI

struct SaveManagerView: View {
    @Environment(\.dismiss) private var dismiss

    private let slots = SaveSlot.samples

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

            Divider()
                .overlay(Theme.separator)

            if slots.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "externaldrive")
                        .font(.system(size: 28))
                    Text("暂无存档")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(slots) { slot in
                            SaveSlotRow(slot: slot)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 560, height: 420)
        .background(Theme.background)
    }
}

private struct SaveSlotRow: View {
    let slot: SaveSlot

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 14) {
            Text("\(slot.index)")
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(slot.chapterTitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(slot.savedAtText) · 游玩 \(Int(slot.playtimeHours)) 小时")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isHovering ? Theme.card : Theme.hover, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .onHover { isHovering = $0 }
    }
}

private struct SaveSlot: Identifiable {
    let id = UUID()
    let index: Int
    let chapterTitle: String
    let savedAt: Date
    let playtimeHours: Double

    var savedAtText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: savedAt)
    }

    static let samples: [SaveSlot] = [
        SaveSlot(index: 1, chapterTitle: "第一章 · 温泉小镇", savedAt: Date().addingTimeInterval(-3600 * 5), playtimeHours: 2.5),
        SaveSlot(index: 2, chapterTitle: "第二章 · 祭典前夜", savedAt: Date().addingTimeInterval(-3600 * 30), playtimeHours: 6.8),
        SaveSlot(index: 3, chapterTitle: "第三章 · 月下的约定", savedAt: Date().addingTimeInterval(-3600 * 80), playtimeHours: 12.4),
        SaveSlot(index: 4, chapterTitle: "最终章 · 千年的愿望", savedAt: Date().addingTimeInterval(-3600 * 200), playtimeHours: 31.2),
    ]
}
