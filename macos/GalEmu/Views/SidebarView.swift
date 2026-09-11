import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var library: GameLibraryController
    @State private var showSortOptions = false
    @State private var showGameScan = false
    @State private var showAppearance = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                librarySection
                engineSettingsSection
                appSettingsSection
                sortSection
            }
            .padding(.horizontal, 12)
            .padding(.top, 34)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 236)
        .background(Theme.sidebar)
        .sheet(isPresented: $showGameScan) {
            GameScanView()
        }
        .sheet(isPresented: $showAppearance) {
            AppearanceSettingsView()
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionTitle("游戏库")
            SidebarRow(icon: "square.grid.2x2", title: "全部游戏", count: library.count(for: .all), isSelected: library.filter == .all) {
                library.filter = .all
            }
            SidebarRow(icon: "star", title: "收藏", count: library.count(for: .favorites), isSelected: library.filter == .favorites) {
                library.filter = .favorites
            }
            SidebarRow(icon: "clock", title: "最近游玩", count: library.count(for: .recent), isSelected: library.filter == .recent) {
                library.filter = .recent
            }
            SidebarRow(icon: "play.circle", title: "游玩中", count: library.count(for: .status(.playing)), isSelected: library.filter == .status(.playing)) {
                library.filter = .status(.playing)
            }
            SidebarRow(icon: "checkmark.circle", title: "已完成", count: library.count(for: .status(.completed)), isSelected: library.filter == .status(.completed)) {
                library.filter = .status(.completed)
            }
            SidebarRow(icon: "circle", title: "未游玩", count: library.count(for: .status(.notStarted)), isSelected: library.filter == .status(.notStarted)) {
                library.filter = .status(.notStarted)
            }
        }
    }

    private var engineSettingsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionTitle("引擎设置")
            ForEach(EngineKind.allCases) { engine in
                SidebarRow(
                    icon: "gearshape",
                    title: engine.rawValue,
                    count: library.count(for: .engine(engine)),
                    isSelected: library.filter == .engine(engine)
                ) {
                    library.filter = .engine(engine)
                }
            }
        }
    }

    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionTitle("应用设置")
            SidebarRow(icon: "magnifyingglass", title: "游戏扫描", isSelected: false) {
                showGameScan = true
            }
            SidebarRow(icon: "paintpalette", title: "外观设置", isSelected: false) {
                showAppearance = true
            }
        }
    }

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionTitle("排列")
            sortRow
        }
    }

    private var sortRow: some View {
        Button {
            showSortOptions.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 13))
                    .frame(width: 18)
                Text("排序: \(library.sort.rawValue)")
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showSortOptions, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(LibrarySort.allCases) { option in
                    SortOptionRow(option: option, isSelected: library.sort == option) {
                        library.sort = option
                        showSortOptions = false
                    }
                }
            }
            .padding(6)
            .frame(width: 150)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.textTertiary)
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
    }
}

private struct SidebarRow: View {
    let icon: String
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject private var appearance: AppearanceSettings
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let count {
                    Text("\(count)")
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Theme.textTertiary)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var rowBackground: Color {
        if isSelected { return appearance.accent.color }
        if isHovering { return Theme.hover }
        return .clear
    }
}

private struct SortOptionRow: View {
    let option: LibrarySort
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.rawValue)
                    .font(.system(size: 13))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .foregroundStyle(isSelected ? Theme.accent : Theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
