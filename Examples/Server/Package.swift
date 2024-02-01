// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-otel-server-example",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(name: "swift-otel", path: "../.."),
        .package(url: "https://github.com/hummingbird-project/hummingbird", exact: "2.0.0-alpha.1"),
    ],
    targets: [
        .executableTarget(
            name: "ServerExample",
            dependencies: [
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "OTLPGRPC", package: "swift-otel"),
                .product(name: "Hummingbird", package: "hummingbird"),
            ]
        )
    ]
)
