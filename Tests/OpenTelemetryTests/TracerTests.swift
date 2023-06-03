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

        let clock = MockClock()
        let span = tracer.startSpan(#function, context: .topLevel, at: clock.now)

        let spanContext = try XCTUnwrap(span.context.spanContext)

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

        let span = tracer.startSpan(#function, context: .topLevel)

        let spanContext = try XCTUnwrap(span.context.spanContext)

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

        let parentSpan = tracer.startSpan("parent", context: .topLevel)
        let childSpan = tracer.startSpan("child", context: parentSpan.context)

        let parentSpanContext = try XCTUnwrap(parentSpan.context.spanContext)
        let childSpanContext = try XCTUnwrap(childSpan.context.spanContext)

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
            traceFlags: [],
            isRemote: true
        )
        var context = ServiceContext.topLevel
        context.spanContext = parentSpanContext
        let span = tracer.startSpan(#function, context: context)

        let spanContext = try XCTUnwrap(span.context.spanContext)

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

        let span = tracer.startSpan(#function, context: .topLevel)

        XCTAssertEqual(span.attributes, ["test": true])
    }

    func test_startedSpan_includesStartTimeFromCustomClock() {
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

        let clock = MockClock()
        clock.setTime(42)

        let span = tracer.startSpan(#function, at: clock.now)

        XCTAssertEqual(span.startTime, 42)
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
        var context = ServiceContext.topLevel
        tracer.extract(headers, into: &context, using: DictionaryExtractor())

        let spanContext = try XCTUnwrap(context.spanContext)

        XCTAssertEqual(
            spanContext,
            OTel.SpanContext(
                traceID: .stub,
                spanID: .stub,
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
        var context = ServiceContext.topLevel
        tracer.extract(headers, into: &context, using: DictionaryExtractor())

        XCTAssertNil(context.spanContext)
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

        let span = tracer.startSpan(#function, context: .topLevel)
        var headers = [String: String]()

        tracer.inject(span.context, into: &headers, using: DictionaryInjector())

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
        parentContext: ServiceContext
    ) -> OTel.SamplingResult {
        let result = sampler.makeSamplingDecision(
            operationName: operationName,
            kind: kind,
            traceID: traceID,
            attributes: attributes,
            links: links,
            parentContext: parentContext
        )
        return OTel.SamplingResult(decision: result.decision, attributes: samplingAttributes)
    }
}
