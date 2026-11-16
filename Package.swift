// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "X2011",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // xtool builds apps from .library products instead of executable targets
        .library(name: "X2011", targets: ["X2011"])
    ],
    targets: [
        .target(name: "X2011")
    ]
)
