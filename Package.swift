// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TyranorMac",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "CXP3",
            path: "CXP3",
            publicHeadersPath: "include",
            linkerSettings: [.linkedLibrary("z")]
        ),
        .executableTarget(
            name: "TyranorMac",
            dependencies: ["CXP3"],
            path: "GalEmu",
            resources: [.process("Resources")]
        )
    ]
)
