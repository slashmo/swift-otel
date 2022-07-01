// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "opentelemetry-swift",
    products: [
        .library(name: "OpenTelemetry", targets: ["OpenTelemetry"]),
        .library(name: "OtlpGRPCSpanExporting", targets: ["OtlpGRPCSpanExporting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "OpenTelemetry", dependencies: [
            .product(name: "Logging", package: "swift-log"),
            .product(name: "Tracing", package: "swift-distributed-tracing"),
            .product(name: "NIO", package: "swift-nio"),
        ]),
        .testTarget(name: "OpenTelemetryTests", dependencies: [
            .target(name: "OpenTelemetry"),
            .product(name: "Tracing", package: "swift-distributed-tracing"),
        ]),

        .target(name: "OtlpGRPCSpanExporting", dependencies: [
            .target(name: "OpenTelemetry"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "GRPC", package: "grpc-swift"),
        ]),
        .testTarget(name: "OtlpGRPCSpanExportingTests", dependencies: [
            .target(name: "OtlpGRPCSpanExporting"),
            .product(name: "NIO", package: "swift-nio"),
        ]),
    ]
)
