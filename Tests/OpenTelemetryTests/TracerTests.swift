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
import XCTest

final class TracerTests: XCTestCase {
    func test_startingRootSpan_generatesTraceAndSpanID() throws {
        let idGenerator = ConstantIDGenerator()
        let tracer = OTel.Tracer(idGenerator: idGenerator)

        let span = tracer.startSpan(#function, baggage: .topLevel)

        let spanContext = try XCTUnwrap(span.baggage.spanContext)

        XCTAssertEqual(spanContext.traceID, idGenerator.traceID)
        XCTAssertEqual(spanContext.spanID, idGenerator.spanID)
        XCTAssertNil(spanContext.parentSpanID, "Root spans shouldn't have a parent span ID.")
    }

    func test_startingChildSpan_generatesSpanID() throws {
        let tracer = OTel.Tracer(idGenerator: OTel.RandomIDGenerator())

        let parentSpan = tracer.startSpan("parent", baggage: .topLevel)
        let childSpan = tracer.startSpan("child", baggage: parentSpan.baggage)

        let parentSpanContext = try XCTUnwrap(parentSpan.baggage.spanContext)
        let childSpanContext = try XCTUnwrap(childSpan.baggage.spanContext)

        XCTAssertEqual(childSpanContext.traceID, childSpanContext.traceID)
        XCTAssertNotEqual(childSpanContext.spanID, parentSpanContext.spanID)
        XCTAssertEqual(childSpanContext.parentSpanID, parentSpanContext.spanID)
    }
}

private struct ConstantIDGenerator: OTel.IDGenerator {
    let traceID = OTel.TraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16))
    let spanID = OTel.SpanID(bytes: (1, 2, 3, 4, 5, 6, 7, 8))

    mutating func generateTraceID() -> OTel.TraceID {
        traceID
    }

    mutating func generateSpanID() -> OTel.SpanID {
        spanID
    }
}
