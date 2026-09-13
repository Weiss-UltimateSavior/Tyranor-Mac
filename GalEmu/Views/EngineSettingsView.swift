import SwiftUI

struct EngineSettingsView: View {
    let engine: EngineKind

    @EnvironmentObject private var settings: EmulatorSettings
    @EnvironmentObject private var krSettings: KREngineSettings
    @EnvironmentObject private var onsSettings: ONSEngineSettings
    @EnvironmentObject private var arSettings: ARTEMISEngineSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if engine == .kirikiri {
                kirikiriSettings
            } else if engine == .ons {
                onsSettingsForm
            } else if engine == .artemis {
                artemisSettingsForm
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(engine.rawValue) 引擎设置")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 28)
        .padding(.top, 34)
        .padding(.bottom, 18)
    }

    private var subtitle: String {
        switch engine {
        case .kirikiri:
            return "krkrsdl3 内核参数，修改后下次启动游戏生效"
        case .artemis:
            return "artemis-compat 内核参数，修改后下次启动游戏生效"
        case .ons:
            return "OnscripterYuri 内核参数，修改后下次启动游戏生效"
        }
    }

    private var kirikiriSettings: some View {
        Form {
            Section("渲染") {
                Picker("渲染后端", selection: $krSettings.renderer) {
                    ForEach(RendererOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Toggle("垂直同步", isOn: $settings.vsyncEnabled)
            }

            Section("窗口") {
                Picker("初始窗口大小", selection: $krSettings.windowSize) {
                    ForEach(WindowSizeOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
    }

    private var onsSettingsForm: some View {
        Form {
            Section("脚本") {
                Picker("文本编码", selection: $onsSettings.encoding) {
                    ForEach(ONSTextEncoding.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            Section("窗口") {
                Picker("窗口大小", selection: $onsSettings.windowSize) {
                    ForEach(ONSWindowSize.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Toggle("全屏启动", isOn: $onsSettings.fullscreen)
            }

            Section("兼容性") {
                Toggle("禁用视频解码", isOn: $onsSettings.disableVideo)
                Toggle("鼠标滚轮前进", isOn: $onsSettings.wheelDownAdvance)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
    }

    private var artemisSettingsForm: some View {
        Form {
            Section("兼容") {
                Picker("平台配置", selection: $arSettings.platform) {
                    ForEach(ARTEMISPlatform.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
    }
}
