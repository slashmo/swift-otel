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

extension OTel {
    /// A `SpanContext` represents the portion of a `Span` which must be serialized and propagated
    /// across asynchronous boundaries.
    ///
    /// - SeeAlso: [OTel Spec: SpanContext](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/api.md#spancontext)
    public struct SpanContext: Equatable {
        /// `TraceID` shared among all spans within one trace.
        public let traceID: TraceID

        /// `SpanID` identifies a single span.
        public internal(set) var spanID: SpanID

        /// `SpanID` of an optional parent span.
        public let parentSpanID: SpanID?

        /// An 8-bit field that controls tracing flags such as sampling, trace level, etc.
        public internal(set) var traceFlags: TraceFlags

        /// The `TraceState` containing potentially vendor-specific trace information.
        public internal(set) var traceState: TraceState?

        /// Whether this context belongs to a remote span.
        public let isRemote: Bool

        /// Initialize a new span context.
        ///
        /// - Parameters:
        ///   - traceID: The trace ID of the span.
        ///   - spanID: The ID of the span itself.
        ///   - parentSpanID: The ID of the optional parent span, defaults to `nil`.
        ///   - traceFlags: The trace flags of the span.
        ///   - traceState: The optional trace state, defaults to `nil`.
        ///   - isRemote: Whether the span is remote.
        ///
        /// - Note: Span contexts should only be created by `OTelPropagator`s when extracting from a carrier.
        public init(
            traceID: OTel.TraceID,
            spanID: OTel.SpanID,
            parentSpanID: OTel.SpanID? = nil,
            traceFlags: OTel.TraceFlags,
            traceState: OTel.TraceState? = nil,
            isRemote: Bool
        ) {
            self.traceID = traceID
            self.spanID = spanID
            self.parentSpanID = parentSpanID
            self.traceFlags = traceFlags
            self.traceState = traceState
            self.isRemote = isRemote
        }
    }
}

#if swift(>=5.5) && canImport(_Concurrency)
extension OTel.SpanContext: Sendable {}
#endif
