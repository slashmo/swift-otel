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

public extension OTel {
    /// A `SpanContext` represents the portion of a `Span` which must be serialized and propagated
    /// across asynchronous boundaries.
    ///
    /// - SeeAlso: [OTel Spec: SpanContext](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/api.md#spancontext)
    struct SpanContext: Equatable {
        /// `TraceID` shared among all spans within one trace.
        public let traceID: TraceID

        /// `SpanID` identifies a single span.
        public internal(set) var spanID: SpanID

        /// `SpanID` of an optional parent span.
        public let parentSpanID: SpanID?

        /// An 8-bit field that controls tracing flags such as sampling, trace level, etc.
        public internal(set) var traceFlags: TraceFlags

        /// The `TraceState` containing potentially vendor-specific trace information.
        public internal(set) var traceState: TraceState
    }
}
