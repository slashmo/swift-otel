// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "opentelemetry-examples-basic",
    dependencies: [
        .package(name: "opentelemetry-swift", path: "../../"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "0.1.4"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "1.0.0-alpha"),
    ],
    targets: [
        .target(name: "Run", dependencies: [
            .product(name: "OpenTelemetry", package: "opentelemetry-swift"),
            .product(name: "OtlpGRPCSpanExporting", package: "opentelemetry-swift"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "Lifecycle", package: "swift-service-lifecycle"),
            .product(name: "LifecycleNIOCompat", package: "swift-service-lifecycle"),
            .product(name: "Tracing", package: "swift-distributed-tracing"),
            .product(name: "TracingOpenTelemetrySupport", package: "swift-distributed-tracing"),
        ]),
    ]
)
