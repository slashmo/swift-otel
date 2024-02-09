//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@testable import OTel
import XCTest

extension Counter {
    private var integerAtomicValue: Int64 { intAtomic.load(ordering: .relaxed) }
    private var doubleAtomicValue: Double { Double(bitPattern: floatAtomic.load(ordering: .relaxed)) }

    package func assertStateEquals(integerPart: Int64, doublePart: Double, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(integerAtomicValue, integerPart, "Unexpected integer part", file: file, line: line)
        XCTAssertEqual(doubleAtomicValue, doublePart, "Unexpected double part", file: file, line: line)
    }
}

extension Gauge {
    package var doubleAtomicValue: Double { Double(bitPattern: atomic.load(ordering: .relaxed)) }
}

extension Histogram {
    private struct EquatableBucket: Equatable {
        var bound: Value
        var count: Int
    }

    package func assertStateEquals(
        count: Int,
        sum: Value,
        buckets: [(bound: Value, count: Int)],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let state = box.withLockedValue { $0 }
        XCTAssertEqual(state.count, count, "Unexpected count", file: file, line: line)
        XCTAssertEqual(state.sum, sum, "Unexpected sum", file: file, line: line)
        XCTAssertEqual(
            state.buckets.map { EquatableBucket(bound: $0.bound, count: $0.count) },
            buckets.map { EquatableBucket(bound: $0.bound, count: $0.count) },
            "Unexpected buckets",
            file: file, line: line
        )
    }
}
