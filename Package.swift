// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "FaceCaptureKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FaceCaptureKit",
            targets: ["FaceCaptureKit"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/getyoti/yoti-face-capture-ios.git",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "FaceCaptureKit",
            dependencies: [
                .product(name: "YotiFaceCapture", package: "yoti-face-capture-ios")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
