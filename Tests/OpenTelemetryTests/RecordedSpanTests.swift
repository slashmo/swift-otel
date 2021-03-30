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
            traceState: nil,
            isRemote: false
        )
        var baggage = Baggage.topLevel
        baggage.spanContext = spanContext
        baggage[TestBaggageKey] = 42

        let startTime = DispatchWallTime.now()
        let endTime = DispatchWallTime.now()
        let status = SpanStatus(code: .ok)
        let attributes: SpanAttributes = ["test": true]
        let events: [SpanEvent] = ["test"]

        let span = OTel.Tracer.Span(
            operationName: #function,
            baggage: baggage,
            kind: .internal,
            startTime: startTime,
            attributes: attributes,
            logger: Logger(label: #function)
        ) { _ in }

        span.addEvent(events[0])
        span.setStatus(status)
        span.addLink(SpanLink(baggage: .topLevel))
        span.end(at: endTime)

        let recordedSpan = try XCTUnwrap(OTel.RecordedSpan(span))

        XCTAssertEqual(recordedSpan.operationName, #function)
        XCTAssertEqual(recordedSpan.kind, .internal)
        XCTAssertEqual(recordedSpan.status, status)
        XCTAssertEqual(recordedSpan.context, spanContext)
        XCTAssertNil(
            recordedSpan.baggage.spanContext,
            "The baggage of a recorded span should not contain the span context."
        )
        XCTAssertEqual(recordedSpan.baggage[TestBaggageKey], 42)
        XCTAssertEqual(recordedSpan.startTime, startTime)
        XCTAssertEqual(recordedSpan.endTime, endTime)
        XCTAssertEqual(recordedSpan.attributes, attributes)
        XCTAssertEqual(recordedSpan.events, events)
        XCTAssertEqual(recordedSpan.links.count, 1)
    }

    func test_initFailsForNonEndedSpans() {
        let spanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: .random(),
            traceFlags: .sampled,
            traceState: nil,
            isRemote: false
        )
        var baggage = Baggage.topLevel
        baggage.spanContext = spanContext

        let span = OTel.Tracer.Span(
            operationName: #function,
            baggage: baggage,
            kind: .internal,
            startTime: .now(),
            attributes: [:],
            logger: Logger(label: #function)
        ) { _ in }

        XCTAssertNil(OTel.RecordedSpan(span), "Non-ended spans should not be convertible to a RecordedSpan.")
    }

    func test_initFailsForContextlessSpans() {
        let span = OTel.Tracer.Span(
            operationName: #function,
            baggage: .topLevel,
            kind: .internal,
            startTime: .now(),
            attributes: [:],
            logger: Logger(label: #function)
        ) { _ in }

        XCTAssertNil(OTel.RecordedSpan(span), "Spans without context should not be convertible to a RecordedSpan.")
    }
}

extension SpanStatus: Equatable {
    public static func == (lhs: SpanStatus, rhs: SpanStatus) -> Bool {
        lhs.code == rhs.code
            && lhs.message == rhs.message
    }
}

private enum TestBaggageKey: BaggageKey {
    typealias Value = Int
}
