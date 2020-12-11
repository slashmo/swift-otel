// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "opentelemetry-collector-example",
    dependencies: [
        .package(name: "opentelemetry-swift", path: "../"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "0.1.1"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "OpenTelemetry", package: "opentelemetry-swift"),
            .product(name: "OtlpTraceExporting", package: "opentelemetry-swift"),
            .product(name: "TracingOpenTelemetrySupport", package: "swift-distributed-tracing"),
        ]),
    ]
)
