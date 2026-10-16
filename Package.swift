// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OliviaLearning",
    platforms: [.macOS(.v12), .iOS(.v16)],
    products: [.library(name: "OliviaLearning", targets: ["OliviaLearning"])],
    targets: [
        .target(name: "OliviaLearning", path: "OliviaPlay/Core"),
        .testTarget(name: "OliviaLearningTests", dependencies: ["OliviaLearning"], path: "Tests")
    ]
)
