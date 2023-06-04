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

import Logging
@testable import OpenTelemetry
import Tracing
import XCTest

final class RecordedSpanTests: XCTestCase {
    func test_initFromRecordedSpan() throws {
        let spanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: .random(),
            traceFlags: .sampled,
            isRemote: false
        )
        var context = ServiceContext.topLevel
        context.spanContext = spanContext
        context[TestContextKey.self] = 42

        let clock = MockClock()
        clock.setTime(42)

        let status = SpanStatus(code: .ok)
        let attributes: SpanAttributes = ["test": true]
        let events: [SpanEvent] = ["test"]

        let span = OTel.Tracer.Span(
            operationName: #function,
            context: context,
            kind: .internal,
            startTime: clock.now.nanosecondsSinceEpoch,
            attributes: attributes,
            resource: OTel.Resource(attributes: ["key": "value"]),
            logger: Logger(label: #function)
        ) { _ in }

        span.addEvent(events[0])
        span.setStatus(status)
        span.addLink(SpanLink(context: .topLevel, attributes: [:]))

        clock.setTime(84)
        span.end(at: clock.now)

        let recordedSpan = try XCTUnwrap(OTel.RecordedSpan(span))

        XCTAssertEqual(recordedSpan.operationName, #function)
        XCTAssertEqual(recordedSpan.kind, .internal)
        XCTAssertEqual(recordedSpan.status, status)
        XCTAssertEqual(recordedSpan.spanContext, spanContext)
        XCTAssertNil(
            recordedSpan.context.spanContext,
            "The service context of a recorded span should not contain the span context."
        )
        XCTAssertEqual(recordedSpan.context[TestContextKey.self], 42)
        XCTAssertEqual(recordedSpan.startTime, 42)
        XCTAssertEqual(recordedSpan.endTime, 84)
        XCTAssertEqual(recordedSpan.attributes, attributes)
        XCTAssertEqual(recordedSpan.events, events)
        XCTAssertEqual(recordedSpan.links.count, 1)
        XCTAssertEqual(recordedSpan.resource.attributes["key"]?.toSpanAttribute(), "value")
    }

    func test_initFailsForNonEndedSpans() {
        let spanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: .random(),
            traceFlags: .sampled,
            isRemote: false
        )
        var context = ServiceContext.topLevel
        context.spanContext = spanContext

        let span = OTel.Tracer.Span.stub()

        XCTAssertNil(OTel.RecordedSpan(span), "Non-ended spans should not be convertible to a RecordedSpan.")
    }

    func test_initFailsForContextlessSpans() {
        let span = OTel.Tracer.Span.stub(spanContext: nil)

        XCTAssertNil(OTel.RecordedSpan(span), "Spans without context should not be convertible to a RecordedSpan.")
    }
}

private enum TestContextKey: ServiceContextKey {
    typealias Value = Int
}
