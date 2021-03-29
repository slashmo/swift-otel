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

        init(idGenerator: IDGenerator) {
            self.idGenerator = idGenerator
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

        if let parentSpanContext = parentBaggage.spanContext {
            childBaggage.spanContext = OTel.SpanContext(
                traceID: parentSpanContext.traceID,
                spanID: idGenerator.generateSpanID(),
                parentSpanID: parentSpanContext.spanID,
                traceFlags: [],
                traceState: OTel.TraceState([])
            )
        } else {
            childBaggage.spanContext = OTel.SpanContext(
                traceID: idGenerator.generateTraceID(),
                spanID: idGenerator.generateSpanID(),
                parentSpanID: nil,
                traceFlags: [],
                traceState: OTel.TraceState([])
            )
        }

        return Span(operationName: operationName, baggage: childBaggage, kind: kind, startTime: time)
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

        init(operationName: String, baggage: Baggage, kind: SpanKind, startTime: DispatchWallTime) {
            self.operationName = operationName
            self.baggage = baggage
            self.kind = kind
            self.startTime = startTime
        }

        func setStatus(_ status: SpanStatus) {}

        func addEvent(_ event: SpanEvent) {}

        func recordError(_ error: Error) {}

        func addLink(_ link: SpanLink) {}

        func end(at time: DispatchWallTime) {}
    }
}
