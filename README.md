# Tyranor Mac

面向 macOS 的原生 Galgame 模拟器（开发中）。

目标是以 Rust 为模拟器核心、SwiftUI/AppKit 为应用层的原生架构（见 [docs/项目技术架构.md](docs/项目技术架构.md)）。
当前阶段已完成应用层实现，模拟器内核以独立进程方式接入。

## 支持的引擎

| 引擎 | 内核 | 状态 |
| --- | --- | --- |
| KIRIKIRI | [krkrsdl3](https://github.com/krkrsdl3/krkrsdl3) | 已接入 |
| ONS | [OnscripterYuri](https://github.com/YuriSizuku/OnscripterYuri) | 已接入 |
| ARTEMIS | art3m1s-core | 规划中 |

## 功能

- **游戏库**：目录扫描与引擎特征识别（扫描层次可调）、收藏、最近游玩、搜索、排序
- **首页**：大图 / 封面流两种样式，封面流背景为当前游戏封面高斯模糊
- **封面与信息**：自动识别本地封面（cover.jpg / icon.png 等）；VNDB / Bangumi / Steam 在线获取，支持候选选择，并随封面写入开发商、发售日、标签、简介
- **存档管理**：按引擎定位存档目录（KR: `savedata/`，ONS: `save/`），支持 zip 导入 / 导出 / 删除
- **在线补丁**：KiriKIRI 补丁索引（[zeas2/Kirikiroid2_patch](https://github.com/zeas2/Kirikiroid2_patch)），搜索并安装到游戏目录
- **引擎设置**：KIRIKIRI（渲染后端、窗口大小、垂直同步）、ONS（文本编码、窗口、全屏、兼容项）参数
- **外观设置**：深浅色、强调色、封面大小与圆角、首页样式与背景模糊
- **其他**：游戏重命名、删除（仅应用内数据）、在访达中显示、打开游戏目录

## 环境要求

- macOS 13+
- Xcode 15+ / Swift 5.9+
- 模拟器内核（可选，自行编译后在 设置 → 内核 中配置路径）：
  - krkrsdl3 构建产物：`krkrsdl3`
  - OnscripterYuri 构建产物：`onsyuri`

## 构建与运行

```bash
swift run TyranorMac
```

或使用 Xcode 打开本仓库根目录（识别 `Package.swift`），选择 scheme `TyranorMac` 运行。

## 目录结构

```
.
├── Package.swift        # SwiftPM 工程（可执行目标 TyranorMac）
├── CXP3/                # XP3 索引解析的 C 桥接（zlib）
├── GalEmu/              # 应用源码
│   ├── App/             # 入口与 AppDelegate
│   ├── Models/          # 数据模型与设置
│   ├── Controllers/     # 游戏库、引擎接入、扫描、封面、存档等
│   ├── Views/           # SwiftUI 界面
│   └── Resources/       # 图标等资源
└── docs/                # 文档
```

## 文档

- [项目技术架构](docs/项目技术架构.md)

## 许可证

本项目基于 [GPL-2.0](LICENSE) 开源。
