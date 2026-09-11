import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: EmulatorSettings

    var body: some View {
        TabView {
            displaySettings
                .tabItem { Label("显示", systemImage: "display") }
            audioSettings
                .tabItem { Label("音频", systemImage: "speaker.wave.2") }
            kernelSettings
                .tabItem { Label("内核", systemImage: "cpu") }
        }
        .frame(width: 520, height: 340)
        .padding(.top, 8)
    }

    private var displaySettings: some View {
        Form {
            Picker("缩放模式", selection: $settings.scaleMode) {
                ForEach(ScaleMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            Toggle("垂直同步", isOn: $settings.vsyncEnabled)
            Toggle("显示性能信息", isOn: $settings.showPerformanceOverlay)
        }
        .formStyle(.grouped)
    }

    private var audioSettings: some View {
        Form {
            volumeRow("主音量", value: $settings.masterVolume)
            volumeRow("BGM", value: $settings.bgmVolume)
            volumeRow("音效", value: $settings.seVolume)
            volumeRow("语音", value: $settings.voiceVolume)
        }
        .formStyle(.grouped)
    }

    private var kernelSettings: some View {
        Form {
            Section("KIRIKIRI（krkrsdl3）") {
                LabeledContent("内核路径") {
                    HStack(spacing: 8) {
                        TextField("", text: $settings.krkrsdl3Path, prompt: Text(CoreLocator.defaultKrkrsdl3Path))
                            .textFieldStyle(.roundedBorder)
                        Button("选择…") { chooseKrkrsdl3() }
                    }
                }
                Text("留空时使用默认构建路径：\(CoreLocator.defaultKrkrsdl3Path)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func volumeRow(_ title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .frame(width: 56, alignment: .leading)
            Slider(value: value, in: 0...1)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func chooseKrkrsdl3() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        panel.message = "选择 krkrsdl3 可执行文件"
        if panel.runModal() == .OK, let url = panel.url {
            settings.krkrsdl3Path = url.path
        }
    }
}
