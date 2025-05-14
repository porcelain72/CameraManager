// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CameraManager",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "CameraManager",
            targets: ["CameraManager"]
        ),
    ],
    targets: [
        .target(
            name: "CameraManager",
            dependencies: [],
            path: "Sources/CameraManager"
        ),
        .testTarget(
            name: "CameraManagerTests",
            dependencies: ["CameraManager"]
        ),
    ]
)

