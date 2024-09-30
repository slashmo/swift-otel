// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "swif-otel-benchmarks",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.0.0"),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "OTelTracing",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "OTel", package: "swift-otel"),
            ],
            path: "Benchmarks/OTelTracing",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
