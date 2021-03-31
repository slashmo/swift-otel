//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2021 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@testable import GRPC
import Logging
import NIO
@testable import OtlpGRPCSpanExporting
import XCTest

final class ConfigTests: XCTestCase {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    func test_usesDefaultHostAndPort() {
        let config = OtlpGRPCSpanExporter.Config(eventLoopGroup: eventLoopGroup)

        XCTAssertEqual(config.host, "localhost")
        XCTAssertEqual(config.port, 4317)
    }

    func test_usesHostAndPortFromEnvironment() {
        let config = OtlpGRPCSpanExporter.Config(
            eventLoopGroup: eventLoopGroup,
            host: nil,
            port: nil,
            logger: Logger(label: #function),
            environment: ["OTEL_EXPORTER_OTLP_ENDPOINT": "http://otel-collector:1234"]
        )

        XCTAssertEqual(config.host, "otel-collector")
        XCTAssertEqual(config.port, 1234)
    }

    func test_prioritizesArgumentsOverEnvironmentVariables() {
        let config = OtlpGRPCSpanExporter.Config(
            eventLoopGroup: eventLoopGroup,
            host: "0.0.0.0",
            port: 5678,
            logger: Logger(label: #function),
            environment: ["OTEL_EXPORTER_OTLP_ENDPOINT": "http://otel-collector:1234"]
        )

        XCTAssertEqual(config.host, "0.0.0.0")
        XCTAssertEqual(config.port, 5678)
    }

    func test_AllowsPortOnlyArgument() {
        let config = OtlpGRPCSpanExporter.Config(
            eventLoopGroup: eventLoopGroup,
            host: nil,
            port: 5678,
            logger: Logger(label: #function),
            environment: [:]
        )

        XCTAssertEqual(config.host, "localhost")
        XCTAssertEqual(config.port, 5678)
    }
}
