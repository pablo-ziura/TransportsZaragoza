// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TransportNetwork",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "TransportNetwork", targets: ["TransportNetwork"])],
    targets: [
        .target(name: "TransportNetwork"),
        .testTarget(name: "TransportNetworkTests", dependencies: ["TransportNetwork"])
    ]
)
