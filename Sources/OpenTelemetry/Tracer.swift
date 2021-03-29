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

import struct Dispatch.DispatchWallTime
import Tracing

extension OTel {
    final class Tracer {
        private var idGenerator: IDGenerator
        private let sampler: Sampler

        init(idGenerator: IDGenerator, sampler: Sampler) {
            self.idGenerator = idGenerator
            self.sampler = sampler
        }
    }
}

extension OTel.Tracer: Instrument {
    func extract<Carrier, Extract>(
        _ carrier: Carrier,
        into baggage: inout Baggage,
        using extractor: Extract
    ) where Carrier == Extract.Carrier, Extract: Extractor {}

    func inject<Carrier, Inject>(
        _ baggage: Baggage,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Injector {}
}

extension OTel.Tracer: Tracer {
    func startSpan(
        _ operationName: String,
        baggage: Baggage,
        ofKind kind: SpanKind,
        at time: DispatchWallTime
    ) -> Tracing.Span {
        let parentBaggage = baggage
        var childBaggage = baggage

        let traceID: OTel.TraceID
        let traceState: OTel.TraceState
        let spanID = idGenerator.generateSpanID()

        if let parentSpanContext = parentBaggage.spanContext {
            traceID = parentSpanContext.traceID
            traceState = parentSpanContext.traceState
        } else {
            traceID = idGenerator.generateTraceID()
            traceState = OTel.TraceState([])
        }

        let samplingResult = sampler.makeSamplingDecision(
            operationName: operationName,
            kind: kind,
            traceID: traceID,
            attributes: [:],
            links: [],
            parentBaggage: parentBaggage
        )
        let traceFlags: OTel.TraceFlags = samplingResult.decision == .recordAndSample ? .sampled : []
        let spanContext = OTel.SpanContext(
            traceID: traceID,
            spanID: spanID,
            parentSpanID: parentBaggage.spanContext?.spanID,
            traceFlags: traceFlags,
            traceState: traceState,
            isRemote: false
        )
        childBaggage.spanContext = spanContext

        if samplingResult.decision == .drop {
            return NoOpTracer.NoOpSpan(baggage: childBaggage)
        }

        return Span(
            operationName: operationName,
            baggage: childBaggage,
            kind: kind,
            startTime: time,
            attributes: samplingResult.attributes
        )
    }

    func forceFlush() {}
}

extension OTel.Tracer {
    final class Span: Tracing.Span {
        let operationName: String
        let startTime: DispatchWallTime
        let baggage: Baggage
        let kind: SpanKind
        let isRecording = false

        var attributes: SpanAttributes = [:]

        init(
            operationName: String,
            baggage: Baggage,
            kind: SpanKind,
            startTime: DispatchWallTime,
            attributes: SpanAttributes
        ) {
            self.operationName = operationName
            self.baggage = baggage
            self.kind = kind
            self.startTime = startTime
            self.attributes = attributes
        }

        func setStatus(_ status: SpanStatus) {}

        func addEvent(_ event: SpanEvent) {}

        func recordError(_ error: Error) {}

        func addLink(_ link: SpanLink) {}

        func end(at time: DispatchWallTime) {}
    }
}
