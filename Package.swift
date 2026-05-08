// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "SSH",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "GeoLite2", targets: ["GeoLite2"]),
        .library(name: "libmaxminddb", targets: ["libmaxminddb"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nvzqz/FileKit.git", .upToNextMinor(from: "6.1.0")),
        .package(url: "https://github.com/foxterm/SSH.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "libmaxminddb"
        ),
        .target(
            name: "GeoLite2",
            dependencies: [
                .target(name: "libmaxminddb"),
                .product(name: "Extension", package: "SSH"),
                .product(name: "FileKit", package: "FileKit"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
