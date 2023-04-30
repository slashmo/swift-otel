// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "basic",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "example", targets: ["Example"]),
    ],
    dependencies: [
        .package(path: "../.."),
        .package(url: "https://github.com/apple/swift-distributed-tracing-extras.git", from: "1.0.0-beta.1"),
    ],
    targets: [
        .executableTarget(name: "Example", dependencies: [
            .product(name: "OpenTelemetry", package: "swift-otel"),
            .product(name: "OtlpGRPCSpanExporting", package: "swift-otel"),
            .product(name: "TracingOpenTelemetrySemanticConventions", package: "swift-distributed-tracing-extras"),
        ]),
    ]
)
