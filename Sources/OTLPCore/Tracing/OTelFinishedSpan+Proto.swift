//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.Data
import OTel
import Tracing

extension Opentelemetry_Proto_Trace_V1_Span {
    /// Create a span from an `OTelFinishedSpan`.
    ///
    /// - Parameter finishedSpan: The `OTelFinishedSpan` to cast.
    public init(_ finishedSpan: OTelFinishedSpan) {
        traceID = Data(finishedSpan.spanContext.traceID.bytes)
        spanID = Data(finishedSpan.spanContext.spanID.bytes)

        if let traceStateHeaderValue = finishedSpan.spanContext.traceStateHeaderValue {
            self.traceState = traceStateHeaderValue
        }

        if let parentSpanID = finishedSpan.spanContext.parentSpanID {
            self.parentSpanID = Data(parentSpanID.bytes)
        }

        name = finishedSpan.operationName
        kind = .init(finishedSpan.kind)

        if let status = finishedSpan.status {
            self.status = .init(status)
        }

        startTimeUnixNano = finishedSpan.startTimeNanosecondsSinceEpoch
        endTimeUnixNano = finishedSpan.endTimeNanosecondsSinceEpoch

        attributes = .init(finishedSpan.attributes)
        events = finishedSpan.events.map(Opentelemetry_Proto_Trace_V1_Span.Event.init)
        links = finishedSpan.links.compactMap(Opentelemetry_Proto_Trace_V1_Span.Link.init)
    }
}
