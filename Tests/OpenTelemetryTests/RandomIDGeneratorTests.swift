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
import XCTest

final class RandomIDGeneratorTests: XCTestCase {
    func test_generatesRandomTraceID_constantMaxValue() {
        var generator = OTel.RandomIDGenerator(randomNumberGenerator: ConstantNumberGenerator(value: .max))

        let maxTraceID = generator.generateTraceID()

        XCTAssertEqual(
            maxTraceID,
            OTel.TraceID(bytes: (255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255))
        )
    }

    func test_generatesRandomTraceID_constantRandomValue() {
        let randomValue = UInt64.random(in: 0 ..< .max)
        let randomHexString = String(randomValue, radix: 16, uppercase: false)
        let pad = String(repeating: "0", count: 16 - randomHexString.count)
        let paddedHexString = "\(pad)\(randomHexString)"
        var generator = OTel.RandomIDGenerator(randomNumberGenerator: ConstantNumberGenerator(value: randomValue))

        let randomTraceID = generator.generateTraceID()

        XCTAssertEqual(randomTraceID.description, paddedHexString + paddedHexString)
    }

    func test_generatesUniqueTraceIDs() {
        var generator = OTel.RandomIDGenerator()
        var traceIDs = Set<OTel.TraceID>()

        for _ in 0 ..< 1000 {
            traceIDs.insert(generator.generateTraceID())
        }

        XCTAssertEqual(traceIDs.count, 1000, "Generating 1000 trace ids should result in 1000 unique trace ids.")
    }

    func test_generatesRandomSpanID_constantMaxValue() {
        var generator = OTel.RandomIDGenerator(randomNumberGenerator: ConstantNumberGenerator(value: .max))

        let maxSpanID = generator.generateSpanID()

        XCTAssertEqual(maxSpanID, OTel.SpanID(bytes: (255, 255, 255, 255, 255, 255, 255, 255)))
    }

    func test_generatesRandomSpanID_constantRandomValue() {
        let randomValue = UInt64.random(in: 0 ..< .max)
        let randomHexString = String(randomValue, radix: 16, uppercase: false)
        let pad = String(repeating: "0", count: 16 - randomHexString.count)
        let paddedHexString = "\(pad)\(randomHexString)"
        var generator = OTel.RandomIDGenerator(randomNumberGenerator: ConstantNumberGenerator(value: randomValue))

        let randomSpanID = generator.generateSpanID()

        XCTAssertEqual(randomSpanID.description, paddedHexString)
    }

    func test_generatesUniqueSpanIDs() {
        var generator = OTel.RandomIDGenerator()
        var spanIDs = Set<OTel.SpanID>()

        for _ in 0 ..< 1000 {
            spanIDs.insert(generator.generateSpanID())
        }

        XCTAssertEqual(spanIDs.count, 1000, "Generating 1000 span ids should result in 1000 unique span ids.")
    }
}

private struct ConstantNumberGenerator: RandomNumberGenerator {
    let value: UInt64

    func next() -> UInt64 {
        value
    }
}
