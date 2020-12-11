//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2020 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Dispatch.DispatchWallTime
import Tracing
import W3CTraceContext

public final class OpenTelemetryTracer: Tracer {
    private let exporter: OpenTelemetryTraceExporter

    public init(exporter: OpenTelemetryTraceExporter) {
        self.exporter = exporter
    }

    public func startSpan(_ operationName: String, baggage: Baggage, ofKind kind: SpanKind, at time: DispatchWallTime) -> Span {
        let parentBaggage = baggage
        var childBaggage = baggage

        if parentBaggage.traceContext != nil {
            // reuse trace-id and trace flags from parent, but generate new parent id
            childBaggage.traceContext?.regenerateParentID()
        } else {
            // start a new trace context
            var traceContext = TraceContext(parent: .random(), state: .none)
            traceContext.sampled = true
            childBaggage.traceContext = traceContext
        }

        let span = OpenTelemetrySpan(name: operationName, kind: kind, startTime: time, baggage: childBaggage) { span in
            do {
                try self.exporter.export(spans: [span]).wait()
            } catch {
                print(error)
            }
        }

        // link as child of previous trace context
        if parentBaggage.traceContext != nil {
            span.addLink(SpanLink(baggage: parentBaggage))
        }

        return span
    }

    public func forceFlush() {
        // no-op
    }

    public func extract<Carrier, Extract>(_ carrier: Carrier, into baggage: inout Baggage, using extractor: Extract)
        where
        Carrier == Extract.Carrier,
        Extract: Extractor {
        if let parent = extractor.extract(key: TraceParent.headerName, from: carrier) {
            let state = extractor.extract(key: TraceState.headerName, from: carrier) ?? ""
            baggage.traceContext = TraceContext(parent: parent, state: state)
        }
    }

    public func inject<Carrier, Inject>(_ baggage: Baggage, into carrier: inout Carrier, using injector: Inject)
        where
        Carrier == Inject.Carrier,
        Inject: Injector {
        guard let traceContext = baggage.traceContext else { return }
        injector.inject(traceContext.parent.rawValue, forKey: TraceParent.headerName, into: &carrier)
        injector.inject(traceContext.state.rawValue, forKey: TraceState.headerName, into: &carrier)
    }
}
