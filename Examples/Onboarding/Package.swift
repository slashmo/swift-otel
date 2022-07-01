// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "onboarding",
    products: [
        .executable(name: "onboarding", targets: ["Onboarding"]),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .target(name: "Onboarding", dependencies: [
            .product(name: "OpenTelemetry", package: "opentelemetry-swift"),
            .product(name: "OtlpGRPCSpanExporting", package: "opentelemetry-swift"),
        ]),
    ]
)
