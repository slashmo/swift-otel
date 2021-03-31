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
    /// A decision on whether a span should be recorded/sampled.
    public enum SamplingDecision {
        /// Don't record the span and drop all events and attributes.
        case drop

        /// Process the span but do not export it.
        case record

        /// Process and export the span.
        case recordAndSample
    }
}

extension OTel {
    /// The result of asking a sampler whether a given span should be sampled.
    public struct SamplingResult {
        /// The resulting sampling decision.
        public let decision: SamplingDecision

        /// Additional attributes that will be included in the span's attributes.
        public let attributes: SpanAttributes

        /// Initialize a sampling result with the given decision and attributes.
        ///
        /// - Parameters:
        ///   - decision: The sampling decision.
        ///   - attributes: Additional attributes to be included in the span's attributes, defaults to no attributes.
        public init(decision: SamplingDecision, attributes: SpanAttributes = [:]) {
            self.decision = decision
            self.attributes = attributes
        }
    }
}
