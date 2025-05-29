// swift-tools-version: 5.9
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import PackageDescription

let package = Package(
    name: "skip-av",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipAV", targets: ["SkipAV"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.2.18"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.17.2")
    ],
    targets: [
        .target(name: "SkipAV", dependencies: [.product(name: "SkipUI", package: "skip-ui")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipAVTests", dependencies: ["SkipAV", .product(name: "SkipTest", package: "skip")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
