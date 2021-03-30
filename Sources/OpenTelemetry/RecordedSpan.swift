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

public extension OTel {
    /// Holds the read-only data collected during the lifetime of a span, typically created right after a span was ended.
    struct RecordedSpan {
        /// The name of the operation this span represents.
        public let operationName: String

        /// The kind of span.
        public let kind: SpanKind

        /// The optional status of this span.
        public let status: SpanStatus?

        /// The context of this span.
        public let context: OTel.SpanContext

        /// The baggage propagated with this span.
        ///
        /// - Note: This `Baggage` doesn't contain the `OTel.SpanContext` as that's already unwrapped and accessible through `self.context`.
        public let baggage: Baggage

        /// The absolute time at which this span was started.
        public let startTime: DispatchWallTime

        /// The absolute time at which this span was ended.
        public let endTime: DispatchWallTime

        /// The attributes describing this span.
        public let attributes: SpanAttributes

        /// The events that occurred during this span.
        public let events: [SpanEvent]

        /// The links to other spans.
        public let links: [SpanLink]
    }
}

extension OTel.RecordedSpan {
    init?(_ span: OTel.Tracer.Span) {
        guard let context = span.baggage.spanContext else { return nil }
        guard let endTime = span.endTime else { return nil }

        self.operationName = span.operationName
        self.kind = span.kind
        self.status = span.status
        self.context = context

        // strip span context from baggage because it's already stored as `context`.
        var baggage = span.baggage
        baggage.spanContext = nil
        self.baggage = baggage

        self.startTime = span.startTime
        self.endTime = endTime

        self.attributes = span.attributes
        self.events = span.events
        self.links = span.links
    }
}
