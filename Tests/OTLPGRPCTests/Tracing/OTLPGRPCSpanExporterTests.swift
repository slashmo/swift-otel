//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 the Swift OTel project authors
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
@testable import OTel
import OTelTesting
import OTLPGRPC
import Tracing
import XCTest

final class OTLPGRPCSpanExporterTests: XCTestCase {
    override func setUp() async throws {
        LoggingSystem.bootstrapInternal(logLevel: .trace)
    }

    func test_export_whenConnected_sendsExportRequestToCollector() async throws {
        let collector = OTLPGRPCMockCollector()

        try await collector.withServer { endpoint in
            let configuration = try OTLPGRPCSpanExporterConfiguration(environment: [:], endpoint: endpoint)
            let exporter = OTLPGRPCSpanExporter(configuration: configuration)

            let span = OTelFinishedSpan.stub()
            try await exporter.export([span])

            await exporter.shutdown()
        }

        XCTAssertEqual(collector.traceProvider.requests.count, 1)
        let request = try XCTUnwrap(collector.traceProvider.requests.first)

        XCTAssertEqual(
            request.headers.first(name: "user-agent"),
            "OTel-OTLP-Exporter-Swift/\(OTelLibrary.version)"
        )
    }

    func test_export_withCustomHeaders_includesCustomHeadersInExportRequest() async throws {
        let collector = OTLPGRPCMockCollector()
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
            let exporter = OTLPGRPCSpanExporter(configuration: configuration)

            try await exporter.export([span])

            await exporter.shutdown()
        }

        XCTAssertEqual(collector.traceProvider.requests.count, 1)
        let request = try XCTUnwrap(collector.traceProvider.requests.first)

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
        let collector = OTLPGRPCMockCollector()

        do {
            try await collector.withServer { endpoint in
                let configuration = try OTLPGRPCSpanExporterConfiguration(environment: [:], endpoint: endpoint)
                let exporter = OTLPGRPCSpanExporter(configuration: configuration)
                await exporter.shutdown()

                let span = OTelFinishedSpan.stub()
                try await exporter.export([span])

                XCTFail("Expected exporter to throw error, successfully exported instead.")
            }
        } catch is OTelSpanExporterAlreadyShutDownError {}
    }
}
