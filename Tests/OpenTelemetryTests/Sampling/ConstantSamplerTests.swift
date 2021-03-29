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

import NIO
import OpenTelemetry
import Tracing
import XCTest

final class ConstantSamplerTests: XCTestCase {
    func test_alwaysOn_returnsRecordAndSample() {
        let sampler = OTel.ConstantSampler(isOn: true)

        let result = sampler.makeSamplingDecision(
            operationName: #function,
            kind: .internal,
            traceID: OTel.TraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
            attributes: [:],
            links: [],
            parentBaggage: .topLevel
        )

        XCTAssertEqual(result.decision, .recordAndSample)
    }

    func test_alwaysOff_returnsDrop() {
        let sampler = OTel.ConstantSampler(isOn: false)

        let result = sampler.makeSamplingDecision(
            operationName: #function,
            kind: .internal,
            traceID: OTel.TraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
            attributes: [:],
            links: [],
            parentBaggage: .topLevel
        )

        XCTAssertEqual(result.decision, .drop)
    }
}
