import SwiftUI

struct CoverSettingsView: View {
    @EnvironmentObject private var library: GameLibraryController
    @EnvironmentObject private var scraper: CoverScraper
    @EnvironmentObject private var coverSettings: CoverSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
            options
            status
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
            footer
        }
        .frame(width: 520, height: 440)
        .background(Theme.background)
    }

    private var header: some View {
        HStack {
            Text("封面获取")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button("完成") { dismiss() }
                .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding(20)
    }

    private var options: some View {
        Form {
            Section("来源") {
                Toggle("VNDB", isOn: $coverSettings.useVNDB)
                Toggle("Bangumi", isOn: $coverSettings.useBangumi)
                Toggle("Steam", isOn: $coverSettings.useSteam)
            }
            Section("行为") {
                Toggle("仅获取缺失封面", isOn: $coverSettings.onlyMissing)
                Text("游戏目录内的 cover.jpg / cover.png / icon.png 等本地封面会优先使用")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 8) {
            if scraper.isRunning || scraper.updatedCount + scraper.skippedCount + scraper.failedCount > 0 {
                ProgressView(value: scraper.progress)
                    .progressViewStyle(.linear)
                Text(scraper.isRunning ? "正在获取：\(scraper.currentTitle)" : "已完成")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("更新 \(scraper.updatedCount) · 跳过 \(scraper.skippedCount) · 失败 \(scraper.failedCount)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Text("共 \(library.games.count) 款，缺封面 \(missingCount) 款")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            if scraper.isRunning {
                Button("取消") { scraper.cancel() }
                    .buttonStyle(SecondaryActionButtonStyle())
            } else {
                Button("开始获取") { start() }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(library.games.isEmpty || coverSettings.enabledSources.isEmpty)
            }
        }
        .padding(20)
    }

    private var missingCount: Int {
        library.games.filter { game in
            guard let path = game.coverPath else { return true }
            return !FileManager.default.fileExists(atPath: path)
        }.count
    }

    private func start() {
        let games = coverSettings.onlyMissing
            ? library.games.filter { game in
                guard let path = game.coverPath else { return true }
                return !FileManager.default.fileExists(atPath: path)
            }
            : library.games

        scraper.scrape(games: games, settings: coverSettings) { id, path, source in
            library.setCover(for: id, path: path, source: source)
        }
    }
}
