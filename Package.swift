// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "opentelemetry-swift",
    products: [
        .library(name: "OpenTelemetry", targets: ["OpenTelemetry"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "0.1.1"),
    ],
    targets: [
        .target(name: "OpenTelemetry", dependencies: [
            .product(name: "Tracing", package: "swift-distributed-tracing"),
        ]),
        .testTarget(name: "OpenTelemetryTests"),
    ]
)
