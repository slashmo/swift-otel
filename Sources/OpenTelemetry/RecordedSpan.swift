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

import Tracing

extension OTel {
    /// Holds the read-only data collected during the lifetime of a span, typically created right after a span was ended.
    public struct RecordedSpan {
        /// The name of the operation this span represents.
        public let operationName: String

        /// The kind of span.
        public let kind: SpanKind

        /// The optional status of this span.
        public let status: SpanStatus?

        /// The context of this span.
        public let spanContext: OTel.SpanContext

        /// The service context propagated with this span.
        ///
        /// - Note: This `ServiceContext` doesn't contain the `OTel.SpanContext` as that's already unwrapped and accessible through `self.context`.
        public let context: ServiceContext

        /// The absolute time at which this span was started.
        public let startTime: UInt64

        /// The absolute time at which this span was ended.
        public let endTime: UInt64

        /// The attributes describing this span.
        public let attributes: SpanAttributes

        /// The events that occurred during this span.
        public let events: [SpanEvent]

        /// The links to other spans.
        public let links: [SpanLink]

        /// The resource on which this span was recorded.
        public let resource: OTel.Resource
    }
}

extension OTel.RecordedSpan {
    init?(_ span: OTel.Tracer.Span) {
        guard let spanContext = span.context.spanContext else { return nil }
        guard let endTime = span.endTime else { return nil }

        operationName = span.operationName
        kind = span.kind
        status = span.status
        self.spanContext = spanContext

        // strip span context from service context because it's already stored as `context`.
        var context = span.context
        context.spanContext = nil
        self.context = context

        startTime = span.startTime
        self.endTime = endTime

        attributes = span.attributes
        events = span.events
        links = span.links
        resource = span.resource
    }
}
