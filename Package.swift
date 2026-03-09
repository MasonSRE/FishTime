// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MoyuCounter",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "MoyuCounter", targets: ["MoyuCounter"]),
    ],
    targets: [
        .executableTarget(
            name: "MoyuCounter",
            path: "MoyuCounter",
            resources: [
                .copy("Resources/AppIcon.icns"),
                .copy("Resources/AppIconFlat.icns"),
            ]
        ),
        .testTarget(
            name: "MoyuCounterTests",
            dependencies: ["MoyuCounter"],
            path: "MoyuCounterTests"
        ),
    ]
)
