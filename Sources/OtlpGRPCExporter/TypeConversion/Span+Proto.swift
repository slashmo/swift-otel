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

import struct Foundation.Data
import OpenTelemetry

extension Opentelemetry_Proto_Trace_V1_Span {
    init(_ span: OTel.RecordedSpan) {
        self.name = span.operationName.replacingOccurrences(of: ".", with: "_")
        self.kind = SpanKind(span.kind)
        self.traceID = Data(span.context.traceID.bytes)
        self.spanID = Data(span.context.spanID.bytes)
        if let parentSpanID = span.context.parentSpanID {
            self.parentSpanID = Data(parentSpanID.bytes)
        }
        if let traceState = span.context.traceState {
            self.traceState = traceState.description
        }
        if let status = span.status {
            self.status = .init(status)
        }
        self.startTimeUnixNano = span.startTime.unixNanoseconds
        self.endTimeUnixNano = span.endTime.unixNanoseconds
        self.attributes = .init(span.attributes)
        self.events = span.events.map(Opentelemetry_Proto_Trace_V1_Span.Event.init)
        self.links = span.links.compactMap(Opentelemetry_Proto_Trace_V1_Span.Link.init)
    }
}
