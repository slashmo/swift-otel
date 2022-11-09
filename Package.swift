// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "opentelemetry-swift",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .watchOS(.v4),
        .tvOS(.v11),
    ],
    products: [
        .executable(name: "Run", targets: ["Run"]),
        .library(name: "OpenTelemetry", targets: ["OpenTelemetry"]),
        .library(name: "OtlpGRPCExporter", targets: ["OtlpGRPCExporter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "Run", dependencies: [
            "OpenTelemetry",
            "OtlpGRPCExporter",
        ]),
        .target(name: "OpenTelemetry", dependencies: [
            .product(name: "Logging", package: "swift-log"),
            .product(name: "Tracing", package: "swift-distributed-tracing"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "Metrics", package: "swift-metrics")
        ]),
        .testTarget(name: "OpenTelemetryTests", dependencies: [
            .target(name: "OpenTelemetry"),
            .product(name: "Tracing", package: "swift-distributed-tracing"),
        ]),

        .target(name: "OtlpGRPCExporter", dependencies: [
            .target(name: "OpenTelemetry"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "Metrics", package: "swift-metrics"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "GRPC", package: "grpc-swift"),
        ]),
        .testTarget(name: "OtlpGRPCExporterTests", dependencies: [
            .target(name: "OtlpGRPCExporter"),
            .product(name: "NIO", package: "swift-nio"),
        ]),
    ]
)
