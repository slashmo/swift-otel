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

    func test_exportsSampledSpans() throws {
        let exporter = InMemorySpanExporter(eventLoopGroup: eventLoopGroup)
        let processor = OTel.SimpleSpanProcessor(exportingTo: exporter)

        let span = OTel.Tracer.Span.stub(spanContext: .stub(traceFlags: .sampled))
        span.end()
        let recordedSpan = try XCTUnwrap(OTel.RecordedSpan(span))

        processor.processEndedSpan(recordedSpan)

        XCTAssertEqual(exporter.spans.count, 1, "Expected sampled span to be exported.")
    }

    func test_ignoresNonSampledSpans() throws {
        let exporter = InMemorySpanExporter(eventLoopGroup: eventLoopGroup)
        let processor = OTel.SimpleSpanProcessor(exportingTo: exporter)

        let span = OTel.Tracer.Span.stub(spanContext: .stub())
        span.end()
        let recordedSpan = try XCTUnwrap(OTel.RecordedSpan(span))

        processor.processEndedSpan(recordedSpan)

        XCTAssertTrue(exporter.spans.isEmpty, "Expected non-sampled span to not be exported.")
    }

    func test_ignoresFailedExports() throws {
        let exporter = FailingSpanExporter(eventLoopGroup: eventLoopGroup, error: TestError.some)
        let processor = OTel.SimpleSpanProcessor(exportingTo: exporter)

        let span = OTel.Tracer.Span.stub()
        span.end()
        let recordedSpan = try XCTUnwrap(OTel.RecordedSpan(span))

        processor.processEndedSpan(recordedSpan)
    }
}

private enum TestError: Error {
    case some
}
