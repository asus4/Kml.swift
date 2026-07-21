// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Kml.swift",
    products: [
        .library(
            name: "Kml.swift",
            targets: ["Kml_swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tadija/AEXML.git", .upToNextMajor(from: "4.7.0")),
    ],
    targets: [
        .target(
            name: "Kml_swift",
            dependencies: ["AEXML"],
            path: "Source"),
        .testTarget(
            name: "KmlTests",
            dependencies: ["AEXML"]),
    ]
)
