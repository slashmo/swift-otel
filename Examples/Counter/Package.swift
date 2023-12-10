// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "swift-otel-counter",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "counter", targets: ["Example"]),
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "OTLPGRPC", package: "swift-otel"),
            ]
        ),
    ]
)
