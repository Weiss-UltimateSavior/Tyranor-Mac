import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SaveManagerView: View {
    let game: Game

    @Environment(\.dismiss) private var dismiss

    @State private var files: [SaveFileInfo] = []
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            if files.isEmpty {
                emptyState
            } else {
                fileList
            }

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
            footer
        }
        .frame(width: 620, height: 480)
        .background(Theme.background)
        .onAppear(perform: reload)
        .alert("操作失败", isPresented: errorBinding) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog("确定删除全部存档吗？此操作不可撤销", isPresented: $showDeleteConfirm) {
            Button("删除全部存档", role: .destructive) { deleteAll() }
            Button("取消", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("存档管理")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("完成") { dismiss() }
                    .buttonStyle(SecondaryActionButtonStyle())
            }
            Text(game.title)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Text(SaveManager.saveDirectory(for: game).path)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(20)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "externaldrive")
                .font(.system(size: 28))
            Text("暂无存档")
                .font(.system(size: 13))
        }
        .foregroundStyle(Theme.textTertiary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileList: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(files) { file in
                    HStack(spacing: 12) {
                        Image(systemName: "doc")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Text("\(file.dateText) · \(file.sizeText)")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.hover, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(20)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text("共 \(files.count) 个文件")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            Button("在访达中显示") {
                let directory = SaveManager.saveDirectory(for: game)
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                NSWorkspace.shared.activateFileViewerSelecting([directory])
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Button("导入…") { importArchive() }
                .buttonStyle(SecondaryActionButtonStyle())

            Button("导出…") { exportArchive() }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(files.isEmpty)

            Button("删除全部") { showDeleteConfirm = true }
                .buttonStyle(SecondaryActionButtonStyle(tint: Theme.favorite))
                .disabled(files.isEmpty)
        }
        .padding(20)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func reload() {
        files = SaveManager.files(for: game)
    }

    private func exportArchive() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = "\(game.title)-存档-\(Self.timestamp()).zip"
        panel.prompt = "导出"
        panel.message = "导出该游戏的存档为 zip 包"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try SaveManager.export(game: game, to: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importArchive() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip]
        panel.prompt = "导入"
        panel.message = "选择存档 zip 包（将覆盖当前存档目录）"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try SaveManager.importZip(game: game, from: url)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteAll() {
        do {
            try SaveManager.deleteAll(game: game)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter.string(from: Date())
    }
}
