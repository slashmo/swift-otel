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

final class TracerTests: XCTestCase {
    func test_startingRootSpan_generatesTraceAndSpanID() throws {
        let idGenerator = StubIDGenerator()
        let sampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: true))
        let tracer = OTel.Tracer(idGenerator: idGenerator, sampler: sampler)

        let span = tracer.startSpan(#function, baggage: .topLevel)

        let spanContext = try XCTUnwrap(span.baggage.spanContext)

        XCTAssertEqual(spanContext.traceID, .stub)
        XCTAssertEqual(spanContext.spanID, .stub)
        XCTAssertNil(spanContext.parentSpanID, "Root spans shouldn't have a parent span ID.")
        XCTAssertTrue(spanContext.traceFlags.contains(.sampled))
        XCTAssertEqual(sampler.numberOfSamplingDecisions, 1)
    }

    func test_startingRootSpan_respectsSamplingDecision() throws {
        let idGenerator = StubIDGenerator()
        let sampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: false))
        let tracer = OTel.Tracer(idGenerator: idGenerator, sampler: sampler)

        let span = tracer.startSpan(#function, baggage: .topLevel)

        let spanContext = try XCTUnwrap(span.baggage.spanContext)

        XCTAssertFalse(spanContext.traceFlags.contains(.sampled))
        XCTAssertEqual(sampler.numberOfSamplingDecisions, 1)
    }

    func test_startingChildSpan_reusesTraceIDButGeneratesNewSpanID() throws {
        let sampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: false))
        let tracer = OTel.Tracer(idGenerator: OTel.RandomIDGenerator(), sampler: sampler)

        let parentSpan = tracer.startSpan("parent", baggage: .topLevel)
        let childSpan = tracer.startSpan("child", baggage: parentSpan.baggage)

        let parentSpanContext = try XCTUnwrap(parentSpan.baggage.spanContext)
        let childSpanContext = try XCTUnwrap(childSpan.baggage.spanContext)

        XCTAssertEqual(childSpanContext.traceID, childSpanContext.traceID)
        XCTAssertNotEqual(childSpanContext.spanID, parentSpanContext.spanID)
        XCTAssertEqual(childSpanContext.parentSpanID, parentSpanContext.spanID)
        XCTAssertFalse(childSpanContext.traceFlags.contains(.sampled))
        XCTAssertEqual(sampler.numberOfSamplingDecisions, 2)
    }

    func test_startingChildSpan_respectsSamplingDecision() throws {
        let idGenerator = StubIDGenerator()
        let sampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: false))
        let tracer = OTel.Tracer(idGenerator: idGenerator, sampler: sampler)

        let parentSpanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: nil,
            traceFlags: [],
            traceState: OTel.TraceState([]),
            isRemote: true
        )
        var baggage = Baggage.topLevel
        baggage.spanContext = parentSpanContext
        let span = tracer.startSpan(#function, baggage: baggage)

        let spanContext = try XCTUnwrap(span.baggage.spanContext)

        XCTAssertFalse(spanContext.traceFlags.contains(.sampled))
        XCTAssertEqual(sampler.numberOfSamplingDecisions, 1)
    }

    func test_startedSpan_includesAttributesFromSamplingDecision() {
        let sampler = AttributedSampler(delegatingTo: OTel.ConstantSampler(isOn: true), attributes: ["test": true])
        let tracer = OTel.Tracer(idGenerator: OTel.RandomIDGenerator(), sampler: sampler)

        let span = tracer.startSpan(#function, baggage: .topLevel)

        XCTAssertEqual(span.attributes, ["test": true])
    }
}

private struct StubIDGenerator: OTel.IDGenerator {
    mutating func generateTraceID() -> OTel.TraceID {
        .stub
    }

    mutating func generateSpanID() -> OTel.SpanID {
        .stub
    }
}

private struct AttributedSampler: OTel.Sampler {
    private let sampler: OTel.Sampler
    private let samplingAttributes: SpanAttributes

    init(delegatingTo sampler: OTel.Sampler, attributes: SpanAttributes) {
        self.sampler = sampler
        samplingAttributes = attributes
    }

    func makeSamplingDecision(
        operationName: String,
        kind: SpanKind,
        traceID: OTel.TraceID,
        attributes: SpanAttributes,
        links: [SpanLink],
        parentBaggage: Baggage
    ) -> OTel.SamplingResult {
        let result = sampler.makeSamplingDecision(
            operationName: operationName,
            kind: kind,
            traceID: traceID,
            attributes: attributes,
            links: links,
            parentBaggage: parentBaggage
        )
        return OTel.SamplingResult(decision: result.decision, attributes: samplingAttributes)
    }
}
