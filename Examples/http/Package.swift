// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "http",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "example", targets: ["Example"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "1.0.0-alpha.11"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.1"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", branch: "feature/request-baggage"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
        .package(url: "https://github.com/slashmo/swift-distributed-tracing.git", branch: "feature/span-event-nanoseconds"),

        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Lifecycle", package: "swift-service-lifecycle"),
                .product(name: "LifecycleNIOCompat", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdFoundation", package: "hummingbird"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "OpenTelemetry", package: "swift-otel"),
                .product(name: "OtlpGRPCSpanExporting", package: "swift-otel"),
            ]
        ),
    ]
)
