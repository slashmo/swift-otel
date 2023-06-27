//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Represents the portion of an ``OTelSpan`` which must be serialized and propagated across asynchronous boundaries.
///
/// [OTel Spec: SpanContext](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/trace/api.md#spancontext)
public struct OTelSpanContext {
    /// The ID of the trace the span belongs to.
    public let traceID: OTelTraceID

    /// The unique ID of this span.
    public let spanID: OTelSpanID

    /// The unique ID of the spans parent or `nil` if it's the root span.
    public let parentSpanID: OTelSpanID?

    /// An 8-bit field controlling tracing flags such as sampling.
    public let traceFlags: OTelTraceFlags

    /// Additional vendor-specific trace identification information.
    public let traceState: OTelTraceState?

    /// Whether this span context belongs to a span that originated on a different service.
    public let isRemote: Bool

    /// Create a span context.
    ///
    /// - Parameters:
    ///   - traceID: The ID of the trace the span belongs to.
    ///   - spanID: The unique ID of this span.
    ///   - parentSpanID: The unique ID of the spans parent or `nil` if it's the root span.
    ///   - traceFlags: An 8-bit field controlling tracing flags such as sampling.
    ///   - traceState: Additional vendor-specific trace identification information.
    ///   - isRemote: Whether this span context belongs to a span that originated on a different service.
    public init(
        traceID: OTelTraceID,
        spanID: OTelSpanID,
        parentSpanID: OTelSpanID?,
        traceFlags: OTelTraceFlags,
        traceState: OTelTraceState?,
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

extension OTelSpanContext: Equatable {}
extension OTelSpanContext: Sendable {}
