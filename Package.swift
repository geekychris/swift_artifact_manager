// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ArtifactCollector",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ArtifactCollector",
            targets: ["ArtifactCollector"]),
    ],
    targets: [
        .target(
            name: "ArtifactCollector",
            path: "ArtifactCollector",
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)
