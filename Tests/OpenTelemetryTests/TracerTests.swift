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

final class TracerTests: XCTestCase {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    // MARK: - Starting spans

    func test_startingRootSpan_generatesTraceAndSpanID() throws {
        let idGenerator = StubIDGenerator()
        let sampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: true))
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: idGenerator,
            sampler: sampler,
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )

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
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: idGenerator,
            sampler: sampler,
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )

        let span = tracer.startSpan(#function, baggage: .topLevel)

        let spanContext = try XCTUnwrap(span.baggage.spanContext)

        XCTAssertFalse(spanContext.traceFlags.contains(.sampled))
        XCTAssertEqual(sampler.numberOfSamplingDecisions, 1)
    }

    func test_startingChildSpan_reusesTraceIDButGeneratesNewSpanID() throws {
        let sampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: false))
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: OTel.RandomIDGenerator(),
            sampler: sampler,
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )

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
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: idGenerator,
            sampler: sampler,
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )

        let parentSpanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: nil,
            traceFlags: [],
            traceState: nil,
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
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: OTel.RandomIDGenerator(),
            sampler: sampler,
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )

        let span = tracer.startSpan(#function, baggage: .topLevel)

        XCTAssertEqual(span.attributes, ["test": true])
    }

    // MARK: - Context Propagation

    func test_extractsSpanContextUsingTheConfiguredPropagator() throws {
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: StubIDGenerator(),
            sampler: OTel.ConstantSampler(isOn: true),
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )

        let headers = [
            "traceparent": "00-0102030405060708090a0b0c0d0e0f10-0102030405060708-01",
            "tracestate": "key=value",
        ]
        var baggage = Baggage.topLevel
        tracer.extract(headers, into: &baggage, using: DictionaryExtractor())

        let spanContext = try XCTUnwrap(baggage.spanContext)

        XCTAssertEqual(
            spanContext,
            OTel.SpanContext(
                traceID: .stub,
                spanID: .stub,
                parentSpanID: nil,
                traceFlags: .sampled,
                traceState: OTel.TraceState([(vendor: "key", value: "value")]),
                isRemote: true
            )
        )
    }

    func test_extractsNoSpanContextIfTheConfiguredPropagatorFails() throws {
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: StubIDGenerator(),
            sampler: OTel.ConstantSampler(isOn: true),
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )

        let headers = ["traceparent": "invalid-trace-parent"]
        var baggage = Baggage.topLevel
        tracer.extract(headers, into: &baggage, using: DictionaryExtractor())

        XCTAssertNil(baggage.spanContext)
    }

    func test_injectsSpanContextUsingTheConfiguredPropagator() {
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: StubIDGenerator(),
            sampler: OTel.ConstantSampler(isOn: true),
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )

        let span = tracer.startSpan(#function, baggage: .topLevel)
        var headers = [String: String]()

        tracer.inject(span.baggage, into: &headers, using: DictionaryInjector())

        XCTAssertEqual(headers["traceparent"], "00-0102030405060708090a0b0c0d0e0f10-0102030405060708-01")
    }

    func test_injectsNothingWithoutASpanContext() {
        let tracer = OTel.Tracer(
            resource: OTel.Resource(),
            idGenerator: StubIDGenerator(),
            sampler: OTel.ConstantSampler(isOn: true),
            processor: OTel.NoOpSpanProcessor(eventLoopGroup: eventLoopGroup),
            propagator: OTel.W3CPropagator(),
            logger: Logger(label: #function)
        )
        var headers = [String: String]()

        tracer.inject(.topLevel, into: &headers, using: DictionaryInjector())

        XCTAssertTrue(headers.isEmpty)
    }
}

private struct StubIDGenerator: OTelIDGenerator {
    mutating func generateTraceID() -> OTel.TraceID {
        .stub
    }

    mutating func generateSpanID() -> OTel.SpanID {
        .stub
    }
}

private struct AttributedSampler: OTelSampler {
    private let sampler: OTelSampler
    private let samplingAttributes: SpanAttributes

    init(delegatingTo sampler: OTelSampler, attributes: SpanAttributes) {
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
