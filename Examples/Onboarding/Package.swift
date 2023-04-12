// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "onboarding",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "onboarding", targets: ["Onboarding"]),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(name: "Onboarding", dependencies: [
            .product(name: "OpenTelemetry", package: "swift-otel"),
            .product(name: "OtlpGRPCSpanExporting", package: "swift-otel"),
        ]),
    ]
)
