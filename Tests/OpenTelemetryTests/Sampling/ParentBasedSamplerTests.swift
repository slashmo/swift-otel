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

@testable import OpenTelemetry
import Tracing
import XCTest

final class ParentBasedSamplerTests: XCTestCase {
    func test_delegatesToRootSpanSampler() {
        let mockSampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: true))
        let sampler = OTel.ParentBasedSampler(rootSampler: mockSampler)

        let result = sampler.testMakeSamplingDecision(parentSpanContext: nil)

        XCTAssertEqual(result.decision, .recordAndSample)
        XCTAssertEqual(
            mockSampler.numberOfSamplingDecisions, 1,
            "Expected root span to be sampled based on the configured root sampler."
        )
    }

    func test_delegatesToRemoteParentSampledSampler() {
        let mockSampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: true))
        let sampler = OTel.ParentBasedSampler(
            rootSampler: OTel.ConstantSampler(isOn: false),
            remoteParentSampledSampler: mockSampler
        )

        let parentSpanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: nil,
            traceFlags: .sampled,
            traceState: nil,
            isRemote: true
        )

        let result = sampler.testMakeSamplingDecision(parentSpanContext: parentSpanContext)

        XCTAssertEqual(result.decision, .recordAndSample)
        XCTAssertEqual(
            mockSampler.numberOfSamplingDecisions, 1,
            "Expected child span to be sampled based on the configured 'sampled remote parent' sampler."
        )
    }

    func test_delegatesToRemoteParentNotSampledSampler() {
        let mockSampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: true))
        let sampler = OTel.ParentBasedSampler(
            rootSampler: OTel.ConstantSampler(isOn: false),
            remoteParentNotSampledSampler: mockSampler
        )

        let parentSpanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: nil,
            traceFlags: [],
            traceState: nil,
            isRemote: true
        )

        let result = sampler.testMakeSamplingDecision(parentSpanContext: parentSpanContext)

        XCTAssertEqual(result.decision, .recordAndSample)
        XCTAssertEqual(
            mockSampler.numberOfSamplingDecisions, 1,
            "Expected child span to be sampled based on the configured 'not-sampled remote parent' sampler."
        )
    }

    func test_delegatesToLocalParentSampledSampler() {
        let mockSampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: true))
        let sampler = OTel.ParentBasedSampler(
            rootSampler: OTel.ConstantSampler(isOn: false),
            localParentSampledSampler: mockSampler
        )

        let parentSpanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: nil,
            traceFlags: .sampled,
            traceState: nil,
            isRemote: false
        )

        let result = sampler.testMakeSamplingDecision(parentSpanContext: parentSpanContext)

        XCTAssertEqual(result.decision, .recordAndSample)
        XCTAssertEqual(
            mockSampler.numberOfSamplingDecisions, 1,
            "Expected child span to be sampled based on the configured 'sampled local parent' sampler."
        )
    }

    func test_delegatesToLocalParentNotSampledSampler() {
        let mockSampler = MockSampler(delegatingTo: OTel.ConstantSampler(isOn: true))
        let sampler = OTel.ParentBasedSampler(
            rootSampler: OTel.ConstantSampler(isOn: false),
            localParentNotSampledSampler: mockSampler
        )

        let parentSpanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: nil,
            traceFlags: [],
            traceState: nil,
            isRemote: false
        )

        let result = sampler.testMakeSamplingDecision(parentSpanContext: parentSpanContext)

        XCTAssertEqual(result.decision, .recordAndSample)
        XCTAssertEqual(
            mockSampler.numberOfSamplingDecisions, 1,
            "Expected child span to be sampled based on the configured 'not-sampled local parent' sampler."
        )
    }
}

private extension OTel.Sampler {
    func testMakeSamplingDecision(
        operationName: String = #function,
        parentSpanContext: OTel.SpanContext?
    ) -> OTel.SamplingResult {
        var baggage = Baggage.topLevel
        baggage.spanContext = parentSpanContext

        return makeSamplingDecision(
            operationName: operationName,
            kind: .internal,
            traceID: OTel.TraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
            attributes: [:],
            links: [],
            parentBaggage: baggage
        )
    }
}
