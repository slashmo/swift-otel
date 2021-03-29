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

public extension OTel {
    /// A sampler that always returns either `OTel.SamplingDecision.recordAndSampled` or `OTel.SamplingDecision.drop`
    /// based on configuration.
    struct ConstantSampler: Sampler {
        private let isOn: Bool

        /// Create a new `ConstantSampler` which always makes the same sampling decision based on the given value.
        ///
        /// - Parameter isOn: Whether to always drop or always record-and-sample new spans.
        public init(isOn: Bool) {
            self.isOn = isOn
        }

        public func makeSamplingDecision(
            operationName: String,
            kind: SpanKind,
            traceID: OTel.TraceID,
            attributes: SpanAttributes,
            links: [SpanLink],
            parentBaggage: Baggage
        ) -> OTel.SamplingResult {
            OTel.SamplingResult(decision: isOn ? .recordAndSample : .drop, attributes: [:])
        }
    }
}
