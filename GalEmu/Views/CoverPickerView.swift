import AppKit
import SwiftUI

struct CoverPickerView: View {
    let game: Game

    @EnvironmentObject private var library: GameLibraryController
    @Environment(\.dismiss) private var dismiss

    @State private var source: CoverSource = .vndb
    @State private var keyword = ""
    @State private var candidates: [CoverCandidate] = []
    @State private var isSearching = false
    @State private var applyingURL: String?
    @State private var errorMessage: String?

    private var sourceOptions: [CoverSource] {
        [.vndb, .bangumi, .steam]
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
        .frame(width: 680, height: 560)
        .background(Theme.background)
        .onAppear {
            keyword = CoverSupport.cleanTitle(game.title)
            Task { await search() }
        }
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
                Text("封面获取")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("完成") { dismiss() }
                    .buttonStyle(SecondaryActionButtonStyle())
            }
            Text("\(game.title) · 从来源选择封面与信息")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
        .padding(20)
    }

    private var searchBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Picker("来源", selection: $source) {
                    ForEach(sourceOptions) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 260)
                .onChange(of: source) { _ in
                    Task { await search() }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                TextField("搜索游戏名", text: $keyword)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { Task { await search() } }
                if !keyword.isEmpty {
                    Button {
                        keyword = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                Button("搜索") { Task { await search() } }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .disabled(isSearching || keyword.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    @ViewBuilder private var content: some View {
        if isSearching {
            VStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("正在搜索…")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if candidates.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 26))
                Text("没有找到候选封面")
                    .font(.system(size: 13))
            }
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(candidates, id: \.url) { candidate in
                        CandidateRow(
                            candidate: candidate,
                            isApplying: applyingURL == candidate.url,
                            isBusy: applyingURL != nil,
                            onUse: { apply(candidate) }
                        )
                    }
                }
                .padding(20)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(isSearching ? "正在搜索…" : "共 \(candidates.count) 个候选")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            if let applyingURL {
                Text("正在应用 \(applyingURL)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(20)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func search() async {
        let query = keyword.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        isSearching = true
        let results = await CoverServices.candidates(query: query, source: source)
        candidates = results
        isSearching = false
    }

    private func apply(_ candidate: CoverCandidate) {
        guard applyingURL == nil else { return }
        applyingURL = candidate.url
        Task {
            let key = CoverSupport.stableKey(game.metadata.directoryPath)
            if let path = await CoverImageCache.download(
                url: candidate.url,
                prefix: "\(candidate.source.rawValue)_\(key)",
                source: candidate.source
            ) {
                library.setCover(
                    for: game.id,
                    path: path,
                    source: candidate.source,
                    metadata: candidate.metadata
                )
                dismiss()
            } else {
                errorMessage = "封面下载失败"
            }
            applyingURL = nil
        }
    }
}

private struct CandidateRow: View {
    let candidate: CoverCandidate
    let isApplying: Bool
    let isBusy: Bool
    let onUse: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: candidate.previewURL ?? candidate.url)
                .frame(width: 56, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(candidate.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                if !candidate.subtitle.isEmpty {
                    Text(candidate.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Text(candidate.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                onUse()
            } label: {
                Text(isApplying ? "应用中…" : "使用")
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(isBusy)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.hover, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct RemoteImage: View {
    let urlString: String?

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            Theme.card
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .clipped()
        .task(id: urlString) {
            await load()
        }
    }

    private func load() async {
        guard let urlString, let url = URL(string: urlString) else { return }
        if let cached = RemoteImageCache.shared.object(forKey: urlString as NSString) {
            image = cached
            return
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let loaded = NSImage(data: data) else { return }
        RemoteImageCache.shared.setObject(loaded, forKey: urlString as NSString)
        image = loaded
    }
}

private enum RemoteImageCache {
    static let shared = NSCache<NSString, NSImage>()
}
