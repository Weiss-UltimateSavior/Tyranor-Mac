import AppKit
import SwiftUI

struct UpdateAvailableView: View {
    let release: UpdateRelease
    let currentVersion: String
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            separator
            info
            notes
            separator
            footer
        }
        .frame(width: 540, height: 480)
        .background(Theme.background)
    }

    private var separator: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 1)
    }

    private var header: some View {
        HStack {
            Text("发现新版本")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button("关闭") { dismiss() }
                .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding(20)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(release.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                if release.isPrerelease {
                    Text("预发布")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.favorite)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.favorite.opacity(0.15), in: Capsule())
                }
            }
            Text("当前版本 \(currentVersion) → 新版本 \(release.version)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            if let publishedAt = release.publishedAt {
                Text("发布于 \(Self.dateFormatter.string(from: publishedAt))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notes: some View {
        ScrollView {
            Text(release.notes.isEmpty ? "（该版本没有填写更新说明）" : release.notes)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button("跳过此版本") {
                onSkip()
                dismiss()
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Spacer()

            Button("稍后") { dismiss() }
                .buttonStyle(SecondaryActionButtonStyle())

            Button("打开发布页") {
                if let url = release.pageURL {
                    NSWorkspace.shared.open(url)
                }
                dismiss()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(release.pageURL == nil)
        }
        .padding(20)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}
