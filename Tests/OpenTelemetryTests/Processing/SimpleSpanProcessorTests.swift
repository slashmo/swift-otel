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

import NIO
@testable import OpenTelemetry
import Tracing
import XCTest

final class SimpleSpanProcessorTests: XCTestCase {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    func test_exportsSampledSpans() {
        let exporter = InMemorySpanExporter(eventLoopGroup: eventLoopGroup)
        let processor = OTel.SimpleSpanProcessor(exportingTo: exporter)

        let span = OTel.RecordedSpan(
            operationName: #function,
            kind: .internal,
            status: nil,
            context: OTel.SpanContext(
                traceID: .random(),
                spanID: .random(),
                parentSpanID: .random(),
                traceFlags: .sampled,
                isRemote: false
            ),
            baggage: .topLevel,
            startTime: .now(),
            endTime: .now() + .seconds(1),
            attributes: [:],
            events: [],
            links: []
        )

        processor.processEndedSpan(span, on: OTel.Resource())

        XCTAssertEqual(exporter.spans.count, 1, "Expected sampled span to be exported.")
    }

    func test_ignoresNonSampledSpans() {
        let exporter = InMemorySpanExporter(eventLoopGroup: eventLoopGroup)
        let processor = OTel.SimpleSpanProcessor(exportingTo: exporter)

        let span = OTel.RecordedSpan(
            operationName: #function,
            kind: .internal,
            status: nil,
            context: OTel.SpanContext(
                traceID: .random(),
                spanID: .random(),
                parentSpanID: .random(),
                traceFlags: [],
                isRemote: false
            ),
            baggage: .topLevel,
            startTime: .now(),
            endTime: .now() + .seconds(1),
            attributes: [:],
            events: [],
            links: []
        )

        processor.processEndedSpan(span, on: OTel.Resource())

        XCTAssertTrue(exporter.spans.isEmpty, "Expected non-sampled span to not be exported.")
    }

    func test_ignoresFailedExports() {
        let exporter = FailingSpanExporter(eventLoopGroup: eventLoopGroup, error: TestError.some)
        let processor = OTel.SimpleSpanProcessor(exportingTo: exporter)

        let span = OTel.RecordedSpan(
            operationName: #function,
            kind: .internal,
            status: nil,
            context: OTel.SpanContext(
                traceID: .random(),
                spanID: .random(),
                parentSpanID: .random(),
                traceFlags: .sampled,
                isRemote: false
            ),
            baggage: .topLevel,
            startTime: .now(),
            endTime: .now() + .seconds(1),
            attributes: [:],
            events: [],
            links: []
        )

        processor.processEndedSpan(span, on: OTel.Resource())
    }
}

private enum TestError: Error {
    case some
}
