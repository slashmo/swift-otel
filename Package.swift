// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "opentelemetry-swift",
    products: [
        .library(name: "OpenTelemetry", targets: ["OpenTelemetry"]),
        .library(name: "OtlpTraceExporting", targets: ["OtlpTraceExporting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "0.1.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0-alpha.20"),
        .package(url: "https://github.com/slashmo/swift-w3c-trace-context.git", from: "0.6.0"),
    ],
    targets: [
        .target(name: "OpenTelemetry", dependencies: [
            .product(name: "Tracing", package: "swift-distributed-tracing"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "W3CTraceContext", package: "swift-w3c-trace-context"),
        ]),
        .testTarget(name: "OpenTelemetryTests"),

        .target(name: "OtlpTraceExporting", dependencies: [
            .target(name: "OpenTelemetry"),
            .product(name: "GRPC", package: "grpc-swift"),
            .product(name: "W3CTraceContext", package: "swift-w3c-trace-context"),
        ]),
    ]
)
