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

@testable import OTel
import Tracing
import XCTest

final class OTelTraceIdRatioBasedSamplerTests: XCTestCase {
    func test_zero_ratio_does_not_sample() {
        let sampler = OTelTraceIdRatioBasedSampler(ratio: 0.0)

        let result = sampler.samplingResult(
            operationName: "does-not-matter",
            kind: .internal,
            traceID: .allZeroes,
            attributes: [:],
            links: [],
            parentContext: .topLevel
        )

        XCTAssertEqual(result, OTelSamplingResult(decision: .drop, attributes: [:]))
    }

    func test_one_ratio_does_sample() {
        let sampler = OTelTraceIdRatioBasedSampler(ratio: 1.0)

        let result = sampler.samplingResult(
            operationName: "does-not-matter",
            kind: .internal,
            traceID: .allZeroes,
            attributes: [:],
            links: [],
            parentContext: .topLevel
        )

        XCTAssertEqual(result, OTelSamplingResult(decision: .recordAndSample, attributes: [:]))
    }

    func test_different_ratios() {
        let ratios = [0.0, 0.1, 0.25, 0.5, 0.75, 1.0]

        for ratio in ratios {
            let sampler = OTelTraceIdRatioBasedSampler(ratio: ratio)

            let N = 100_000
            var sampled = 0

            for _ in 0 ..< N {
                let result = sampler.samplingResult(
                    operationName: "does-not-matter",
                    kind: .internal,
                    traceID: .random(),
                    attributes: [:],
                    links: [],
                    parentContext: .topLevel
                )

                switch result.decision {
                case .recordAndSample:
                    sampled += 1
                default: break
                }
            }

            let observedRatio = Double(sampled) / Double(N)

            XCTAssertEqual(ratio, observedRatio, accuracy: 0.05, "Expected ratio \(ratio) but observed \(observedRatio)")
        }
    }

    func test_equality() {
        let sampler1 = OTelTraceIdRatioBasedSampler(ratio: 0.5)
        let sampler2 = OTelTraceIdRatioBasedSampler(ratio: 0.5)
        let sampler3 = OTelTraceIdRatioBasedSampler(ratio: 0.75)

        XCTAssertEqual(sampler1, sampler2)
        XCTAssertNotEqual(sampler1, sampler3)
    }

    func test_hashable() {
        let sampler1 = OTelTraceIdRatioBasedSampler(ratio: 0.5)
        let sampler2 = OTelTraceIdRatioBasedSampler(ratio: 0.5)
        let sampler3 = OTelTraceIdRatioBasedSampler(ratio: 0.75)

        XCTAssertEqual(sampler1.hashValue, sampler2.hashValue)
        XCTAssertNotEqual(sampler1.hashValue, sampler3.hashValue)
    }

    func test_description() {
        let sampler = OTelTraceIdRatioBasedSampler(ratio: 0.5)

        XCTAssertEqual("\(sampler)", "TraceIdRatioBased{0.5}")
    }
}
