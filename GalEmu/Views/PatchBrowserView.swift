import SwiftUI

struct PatchBrowserView: View {
    let game: Game

    @Environment(\.dismiss) private var dismiss

    @State private var entries: [KirikiroidPatchEntry] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var installingID: UUID?
    @State private var statusText = ""
    @State private var errorMessage: String?

    private var filtered: [KirikiroidPatchEntry] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return entries }
        return entries.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.brand.localizedCaseInsensitiveContains(query)
                || $0.path.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            separator
            searchBar
            content
            separator
            footer
        }
        .frame(width: 640, height: 520)
        .background(Theme.background)
        .task { await load() }
        .alert("操作失败", isPresented: errorBinding) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 1)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("在线补丁")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("完成") { dismiss() }
                    .buttonStyle(SecondaryActionButtonStyle())
            }
            Text("\(game.title) · 补丁将写入游戏目录并覆盖同名文件")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
        .padding(20)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
            TextField("搜索游戏名 / 品牌 / 路径", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    @ViewBuilder private var content: some View {
        if isLoading {
            VStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("正在获取补丁列表…")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filtered.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 26))
                Text(entries.isEmpty ? "没有可用的补丁数据" : "没有匹配的补丁")
                    .font(.system(size: 13))
            }
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(filtered) { entry in
                        PatchRow(
                            entry: entry,
                            isInstalling: installingID == entry.id,
                            isBusy: installingID != nil,
                            onInstall: { install(entry) }
                        )
                    }
                }
                .padding(20)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(statusText)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text("共 \(filtered.count) 条")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(20)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func load() async {
        guard entries.isEmpty else { return }
        isLoading = true
        do {
            entries = try await KrkrPatchService.fetchIndex()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func install(_ entry: KirikiroidPatchEntry) {
        guard installingID == nil else { return }
        installingID = entry.id
        statusText = ""
        Task {
            do {
                let files = try await KrkrPatchService.install(entry: entry, into: game) { status in
                    statusText = status
                }
                statusText = "已写入 \(files.count) 个文件到游戏目录"
            } catch {
                errorMessage = error.localizedDescription
                statusText = ""
            }
            installingID = nil
        }
    }
}

private struct PatchRow: View {
    let entry: KirikiroidPatchEntry
    let isInstalling: Bool
    let isBusy: Bool
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button {
                onInstall()
            } label: {
                Text(isInstalling ? "安装中…" : "安装")
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(isBusy)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.hover, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var detail: String {
        var parts: [String] = []
        if !entry.brand.isEmpty { parts.append(entry.brand) }
        if !entry.path.isEmpty { parts.append(entry.path) }
        parts.append("\(entry.patches.count) 个文件")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        parts.append(formatter.string(from: entry.timestamp))
        return parts.joined(separator: " · ")
    }
}
