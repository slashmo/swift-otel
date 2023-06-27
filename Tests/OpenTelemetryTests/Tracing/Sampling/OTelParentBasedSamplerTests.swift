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

@testable import OpenTelemetry
import Tracing
import XCTest

final class OTelParentBasedSamplerTests: XCTestCase {
    private var rootSampler: RecordingSampler!
    private var remoteParentSampledSampler: RecordingSampler!
    private var remoteParentNotSampledSampler: RecordingSampler!
    private var localParentSampledSampler: RecordingSampler!
    private var localParentNotSampledSampler: RecordingSampler!

    override func setUp() {
        rootSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: false))
        remoteParentSampledSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: false))
        remoteParentNotSampledSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: false))
        localParentSampledSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: false))
        localParentNotSampledSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: false))
    }

    func test_samplingResult_withoutParent_invokesRootSampler() {
        rootSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: true))
        let sampler = sampler()

        let result = sampler.samplingResult(
            operationName: "does-not-matter",
            kind: .internal,
            traceID: .allZeroes,
            attributes: [:],
            links: [],
            parentContext: .topLevel
        )

        XCTAssertEqual(result, OTelSamplingResult(decision: .recordAndSample, attributes: [:]))
        XCTAssertEqual(rootSampler.results, [result])
    }

    func test_samplingResult_withSampledRemoteParent_invokesRemoteParentSampledSampler() {
        remoteParentSampledSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: true))
        let sampler = sampler()

        var parentContext = ServiceContext.topLevel
        parentContext.spanContext = .stub(traceFlags: .sampled, isRemote: true)

        let result = sampler.samplingResult(
            operationName: "does-not-matter",
            kind: .internal,
            traceID: .allZeroes,
            attributes: [:],
            links: [],
            parentContext: parentContext
        )

        XCTAssertEqual(result, OTelSamplingResult(decision: .recordAndSample, attributes: [:]))
        XCTAssertEqual(remoteParentSampledSampler.results, [result])
    }

    func test_samplingResult_withNonSampledRemoteParent_invokesRemoteParentNotSampledSampler() {
        remoteParentNotSampledSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: true))
        let sampler = sampler()

        var parentContext = ServiceContext.topLevel
        parentContext.spanContext = .stub(traceFlags: [], isRemote: true)

        let result = sampler.samplingResult(
            operationName: "does-not-matter",
            kind: .internal,
            traceID: .allZeroes,
            attributes: [:],
            links: [],
            parentContext: parentContext
        )

        XCTAssertEqual(result, OTelSamplingResult(decision: .recordAndSample, attributes: [:]))
        XCTAssertEqual(remoteParentNotSampledSampler.results, [result])
    }

    func test_samplingResult_withSampledLocalParent_invokesLocalParentSampledSampler() {
        localParentSampledSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: true))
        let sampler = sampler()

        var parentContext = ServiceContext.topLevel
        parentContext.spanContext = .stub(traceFlags: .sampled, isRemote: false)

        let result = sampler.samplingResult(
            operationName: "does-not-matter",
            kind: .internal,
            traceID: .allZeroes,
            attributes: [:],
            links: [],
            parentContext: parentContext
        )

        XCTAssertEqual(result, OTelSamplingResult(decision: .recordAndSample, attributes: [:]))
        XCTAssertEqual(localParentSampledSampler.results, [result])
    }

    func test_samplingResult_withNonSampledLocalParent_invokesLocalParentNotSampledSampler() {
        localParentNotSampledSampler = RecordingSampler(sampler: OTelConstantSampler(isOn: true))
        let sampler = sampler()

        var parentContext = ServiceContext.topLevel
        parentContext.spanContext = .stub(traceFlags: [], isRemote: false)

        let result = sampler.samplingResult(
            operationName: "does-not-matter",
            kind: .internal,
            traceID: .allZeroes,
            attributes: [:],
            links: [],
            parentContext: parentContext
        )

        XCTAssertEqual(result, OTelSamplingResult(decision: .recordAndSample, attributes: [:]))
        XCTAssertEqual(localParentNotSampledSampler.results, [result])
    }

    private func sampler() -> OTelParentBasedSampler {
        OTelParentBasedSampler(
            rootSampler: rootSampler,
            remoteParentSampledSampler: remoteParentSampledSampler,
            remoteParentNotSampledSampler: remoteParentNotSampledSampler,
            localParentSampledSampler: localParentSampledSampler,
            localParentNotSampledSampler: localParentNotSampledSampler
        )
    }
}

// MARK: - Helpers

private final class RecordingSampler: OTelSampler {
    private let sampler: any OTelSampler
    private(set) var results = [OTelSamplingResult]()

    init(sampler: any OTelSampler) {
        self.sampler = sampler
    }

    func samplingResult(
        operationName: String,
        kind: SpanKind,
        traceID: OTelTraceID,
        attributes: SpanAttributes,
        links: [SpanLink],
        parentContext: ServiceContext
    ) -> OTelSamplingResult {
        let result = sampler.samplingResult(
            operationName: operationName,
            kind: kind,
            traceID: traceID,
            attributes: attributes,
            links: links,
            parentContext: parentContext
        )
        results.append(result)
        return result
    }
}
