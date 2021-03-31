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
    /// A sampler composed of multiple configurable samplers which are called based on whether
    /// the parent span is remote and/or sampled, or doesn't exist.
    public struct ParentBasedSampler: OTelSampler {
        private let rootSampler: OTelSampler
        private let remoteParentSampledSampler: OTelSampler
        private let remoteParentNotSampledSampler: OTelSampler
        private let localParentSampledSampler: OTelSampler
        private let localParentNotSampledSampler: OTelSampler

        /// Initialize a new parent based sampler delegating to the given samplers.
        ///
        /// - Parameters:
        ///   - rootSampler: Called whenever a span doesn't have a parent, i.e. is the root span.
        ///   - remoteParentSampledSampler: Called whenever a span has a remote parent which *is* sampled. Defaults to an *always on* sampler.
        ///   - remoteParentNotSampledSampler: Called whenever a span has a remote parent which *is not* sampled.
        ///   Defaults to an *always off* sampler.
        ///   - localParentSampledSampler: Called whenever a span has a local parent which *is* sampled. Defaults to an *always on* sampler.
        ///   - localParentNotSampledSampler: Called whenever a span has a local parent which *is not* sampled.
        ///   Defaults to an *always off* sampler.
        public init(
            rootSampler: OTelSampler,
            remoteParentSampledSampler: OTelSampler = ConstantSampler(isOn: true),
            remoteParentNotSampledSampler: OTelSampler = ConstantSampler(isOn: false),
            localParentSampledSampler: OTelSampler = ConstantSampler(isOn: true),
            localParentNotSampledSampler: OTelSampler = ConstantSampler(isOn: false)
        ) {
            self.rootSampler = rootSampler
            self.remoteParentSampledSampler = remoteParentSampledSampler
            self.remoteParentNotSampledSampler = remoteParentNotSampledSampler
            self.localParentSampledSampler = localParentSampledSampler
            self.localParentNotSampledSampler = localParentNotSampledSampler
        }

        public func makeSamplingDecision(
            operationName: String,
            kind: SpanKind,
            traceID: OTel.TraceID,
            attributes: SpanAttributes,
            links: [SpanLink],
            parentBaggage: Baggage
        ) -> OTel.SamplingResult {
            guard let parentSpanContext = parentBaggage.spanContext else {
                return rootSampler.makeSamplingDecision(
                    operationName: operationName,
                    kind: kind,
                    traceID: traceID,
                    attributes: attributes,
                    links: links,
                    parentBaggage: parentBaggage
                )
            }

            let sampler: OTelSampler

            switch (parentSpanContext.isRemote, parentSpanContext.traceFlags.contains(.sampled)) {
            case (true, true):
                sampler = remoteParentSampledSampler
            case (true, false):
                sampler = remoteParentNotSampledSampler
            case (false, true):
                sampler = localParentSampledSampler
            case (false, false):
                sampler = localParentNotSampledSampler
            }

            return sampler.makeSamplingDecision(
                operationName: operationName,
                kind: kind,
                traceID: traceID,
                attributes: attributes,
                links: links,
                parentBaggage: parentBaggage
            )
        }
    }
}
