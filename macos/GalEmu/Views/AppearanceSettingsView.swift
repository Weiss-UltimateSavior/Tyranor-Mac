import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var appearance: AppearanceSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("外观设置")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("完成") { dismiss() }
                    .buttonStyle(SecondaryActionButtonStyle())
            }
            .padding(20)

            Divider()
                .overlay(Theme.separator)

            Form {
                Section("主题") {
                    Picker("深浅色", selection: $appearance.themeMode) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("强调色") {
                    HStack(spacing: 14) {
                        ForEach(AccentPalette.allCases) { palette in
                            Button {
                                appearance.accent = palette
                            } label: {
                                Circle()
                                    .fill(palette.color)
                                    .frame(width: 22, height: 22)
                                    .overlay {
                                        if appearance.accent == palette {
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: 2)
                                                .padding(-3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .help(palette.rawValue)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }

                Section("封面") {
                    Picker("封面大小", selection: $appearance.coverSize) {
                        ForEach(CoverSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    Picker("封面圆角", selection: $appearance.coverCorner) {
                        ForEach(CoverCorner.allCases) { corner in
                            Text(corner.rawValue).tag(corner)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 470, height: 380)
        .background(Theme.background)
    }
}
