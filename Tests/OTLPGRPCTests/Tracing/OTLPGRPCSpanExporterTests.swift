//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import GRPC
@testable import Logging
import NIO
@testable import OpenTelemetry
import OTelTesting
import OTLPGRPC
import Tracing
import XCTest

final class OTLPGRPCSpanExporterTests: XCTestCase {
    private var group: MultiThreadedEventLoopGroup!

    override func setUp() async throws {
        LoggingSystem.bootstrapInternal(logLevel: .trace)
        group = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    }

    override func tearDown() async throws {
        try await group.shutdownGracefully()
    }

    func test_export_whenConnected_sendsExportRequestToCollector() async throws {
        let collector = OTLPGRPCTraceCollectorMock(group: group)

        try await collector.withServer { endpoint in
            let configuration = try OTLPGRPCSpanExporterConfiguration(environment: [:], endpoint: endpoint)
            let exporter = OTLPGRPCSpanExporter(configuration: configuration, group: group)

            let span = OTelFinishedSpan.stub()
            try await exporter.export([span])

            await exporter.shutdown()
        }

        XCTAssertEqual(collector.requests.count, 1)
        let request = try XCTUnwrap(collector.requests.first)

        XCTAssertEqual(
            request.headers.first(name: "user-agent"),
            "OTel-OTLP-Exporter-Swift/\(OTelLibrary.version)"
        )
    }

    func test_export_withCustomHeaders_includesCustomHeadersInExportRequest() async throws {
        let collector = OTLPGRPCTraceCollectorMock(group: group)
        let span = OTelFinishedSpan.stub(resource: OTelResource(attributes: ["service.name": "test"]))

        try await collector.withServer { endpoint in
            let configuration = try OTLPGRPCSpanExporterConfiguration(
                environment: [:],
                endpoint: endpoint,
                headers: [
                    "key1": "42",
                    "key2": "84",
                ]
            )
            let exporter = OTLPGRPCSpanExporter(configuration: configuration, group: group)

            try await exporter.export([span])

            await exporter.shutdown()
        }

        XCTAssertEqual(collector.requests.count, 1)
        let request = try XCTUnwrap(collector.requests.first)

        XCTAssertEqual(request.exportRequest.resourceSpans.count, 1)
        let resourceSpans = try XCTUnwrap(request.exportRequest.resourceSpans.first)
        XCTAssertEqual(resourceSpans.resource, .with {
            $0.attributes = .init(["service.name": "test"])
        })
        XCTAssertEqual(resourceSpans.scopeSpans.count, 1)
        let scopeSpans = try XCTUnwrap(resourceSpans.scopeSpans.first)
        XCTAssertEqual(scopeSpans.scope, .with {
            $0.name = "swift-otel"
            $0.version = OTelLibrary.version
        })
        XCTAssertEqual(scopeSpans.spans, [.init(span)])

        XCTAssertEqual(request.headers.first(name: "key1"), "42")
        XCTAssertEqual(request.headers.first(name: "key2"), "84")
    }

    func test_export_whenAlreadyShutdown_throwsAlreadyShutdownError() async throws {
        let collector = OTLPGRPCTraceCollectorMock(group: group)

        do {
            try await collector.withServer { endpoint in
                let configuration = try OTLPGRPCSpanExporterConfiguration(environment: [:], endpoint: endpoint)
                let exporter = OTLPGRPCSpanExporter(configuration: configuration, group: group)
                await exporter.shutdown()

                let span = OTelFinishedSpan.stub()
                try await exporter.export([span])

                XCTFail("Expected exporter to throw error, successfully exported instead.")
            }
        } catch is OTelSpanExporterAlreadyShutDownError {}
    }
}
