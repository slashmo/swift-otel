// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "opentelemetry-swift",
    products: [
        .library(name: "OpenTelemetry", targets: ["OpenTelemetry"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "0.1.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "OpenTelemetry", dependencies: [
            .product(name: "Tracing", package: "swift-distributed-tracing"),
            .product(name: "NIO", package: "swift-nio"),
        ]),
        .testTarget(name: "OpenTelemetryTests", dependencies: [
            .target(name: "OpenTelemetry"),
            .product(name: "Tracing", package: "swift-distributed-tracing"),
        ]),
    ]
)
