// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "streamdown-swift-ui",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "StreamdownSwiftUI",
            targets: ["StreamdownSwiftUI"]
        ),
    ],
    targets: [
        .target(
            name: "StreamdownSwiftUI",
            path: "Sources/StreamdownSwiftUI"
        ),
        .testTarget(
            name: "StreamdownSwiftUITests",
            dependencies: ["StreamdownSwiftUI"],
            path: "Tests/StreamdownSwiftUITests"
        ),
    ]
)
