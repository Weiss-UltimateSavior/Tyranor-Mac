import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var library: GameLibraryController
    @EnvironmentObject private var updateChecker: UpdateChecker
    @EnvironmentObject private var appearance: AppearanceSettings
    @AppStorage("sidebar.collapsed") private var isCollapsed = false
    @State private var showSortOptions = false
    @State private var showGameScan = false
    @State private var showCoverSettings = false
    @State private var showAppearance = false
    @State private var showUpdateSheet = false
    @State private var updateAlertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapseHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    librarySection
                    engineSettingsSection
                    appSettingsSection
                }
                .padding(.horizontal, isCollapsed ? 6 : 12)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: isCollapsed ? .center : .leading)
            }
        }
        .frame(width: isCollapsed ? 80 : 189)
        .background(Theme.sidebar)
        .sheet(isPresented: $showGameScan) {
            GameScanView()
        }
        .sheet(isPresented: $showCoverSettings) {
            CoverSettingsView()
        }
        .sheet(isPresented: $showAppearance) {
            AppearanceSettingsView()
        }
        .sheet(isPresented: $showUpdateSheet) {
            if case let .available(release) = updateChecker.state {
                UpdateAvailableView(
                    release: release,
                    currentVersion: updateChecker.currentVersion,
                    onSkip: { updateChecker.skip(release) }
                )
            }
        }
        .onChange(of: updateChecker.state) { state in
            switch state {
            case .available:
                showUpdateSheet = true
            case .upToDate:
                if updateChecker.isManualCheck {
                    updateAlertMessage = "当前已是最新版本（\(updateChecker.currentVersion)）"
                }
                updateChecker.reset()
            case let .failed(message):
                if updateChecker.isManualCheck {
                    updateAlertMessage = message
                }
                updateChecker.reset()
            default:
                break
            }
        }
        .alert("检查更新", isPresented: updateAlertBinding) {
            Button("好", role: .cancel) {}
        } message: {
            Text(updateAlertMessage ?? "")
        }
    }

    private var updateAlertBinding: Binding<Bool> {
        Binding(
            get: { updateAlertMessage != nil },
            set: { if !$0 { updateAlertMessage = nil } }
        )
    }

    private var collapseHeader: some View {
        HStack(spacing: 8) {
            if !isCollapsed {
                Text("Tyranor Next")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(appearance.accent.color)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isCollapsed.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isCollapsed ? "展开侧边栏" : "收起侧边栏")
            if isCollapsed {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, isCollapsed ? 0 : 10)
        .padding(.top, 30)
        .padding(.bottom, 8)
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionTitle("游戏库")
            SidebarRow(icon: "house", title: "首页", isSelected: library.selection == .home, isCompact: isCollapsed) {
                library.selection = .home
            }
            SidebarRow(icon: "square.grid.2x2", title: "全部游戏", count: library.count(for: .all), isSelected: library.selection == .library(.all), isCompact: isCollapsed) {
                library.selection = .library(.all)
            }
            SidebarRow(icon: "star", title: "收藏", count: library.count(for: .favorites), isSelected: library.selection == .library(.favorites), isCompact: isCollapsed) {
                library.selection = .library(.favorites)
            }
            SidebarRow(icon: "clock", title: "最近游玩", count: library.count(for: .recent), isSelected: library.selection == .library(.recent), isCompact: isCollapsed) {
                library.selection = .library(.recent)
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
                    isSelected: library.selection == .engine(engine),
                    isCompact: isCollapsed
                ) {
                    library.selection = .engine(engine)
                }
            }
        }
    }

    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionTitle("应用设置")
            SidebarRow(icon: "magnifyingglass", title: "游戏扫描", isSelected: false, isCompact: isCollapsed) {
                showGameScan = true
            }
            SidebarRow(icon: "photo.on.rectangle", title: "封面获取", isSelected: false, isCompact: isCollapsed) {
                showCoverSettings = true
            }
            SidebarRow(icon: "paintpalette", title: "外观设置", isSelected: false, isCompact: isCollapsed) {
                showAppearance = true
            }
            SidebarRow(icon: "arrow.triangle.2.circlepath", title: "检查更新", isSelected: false, isCompact: isCollapsed) {
                Task { await updateChecker.check(manual: true) }
            }
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
                if !isCollapsed {
                    Text("游戏排序")
                        .font(.system(size: 13))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, isCollapsed ? 6 : 10)
            .padding(.vertical, 7)
            .frame(maxWidth: isCollapsed ? .infinity : nil, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("游戏排序：\(library.sort.rawValue)")
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

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        if isCollapsed {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
                .padding(.horizontal, 6)
                .padding(.bottom, 2)
        } else {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
        }
    }
}

private struct SidebarRow: View {
    let icon: String
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    var isCompact: Bool = false
    let action: () -> Void

    @EnvironmentObject private var appearance: AppearanceSettings
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 18)
                if !isCompact {
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
            }
            .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
            .padding(.horizontal, isCompact ? 6 : 10)
            .padding(.vertical, 7)
            .frame(maxWidth: isCompact ? .infinity : nil, alignment: .center)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(title)
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
