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

/// Decides whether a given span should be sampled i.e. passed along to the span exporter.
public protocol OTelSampler {
    /// Make a decision on whether to sample a span to be started based on the
    /// information available at this time.
    ///
    /// - Parameters:
    ///   - operationName: The name of the span.
    ///   - kind: The kind of span.
    ///   - traceID: The trace id, either propagated or newly generated.
    ///   - attributes: A set of default span attributes.
    ///   - links: A set of default span links.
    ///   - parentBaggage: The parent baggage which might contain a `OTel.SpanContext`.
    /// - Returns: A decision on whether the span to be started should be dropped, only recorded, or recorded and sampled.
    func makeSamplingDecision(
        operationName: String,
        kind: SpanKind,
        traceID: OTel.TraceID,
        attributes: SpanAttributes,
        links: [SpanLink],
        parentBaggage: Baggage
    ) -> OTel.SamplingResult
}

public extension OTel {
    typealias Sampler = OTelSampler
}
