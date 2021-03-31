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

import OpenTelemetry
import Tracing

final class MockSampler: OTelSampler {
    private(set) var numberOfSamplingDecisions: Int = 0
    private let sampler: OTelSampler

    init(delegatingTo sampler: OTelSampler) {
        self.sampler = sampler
    }

    func makeSamplingDecision(
        operationName: String,
        kind: SpanKind,
        traceID: OTel.TraceID,
        attributes: SpanAttributes,
        links: [SpanLink],
        parentBaggage: Baggage
    ) -> OTel.SamplingResult {
        numberOfSamplingDecisions += 1
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
