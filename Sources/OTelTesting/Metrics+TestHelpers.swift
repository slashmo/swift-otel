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

@testable @_spi(Metrics) import OTel
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

extension OTelMetricPoint.OTelMetricData {
    package var asSum: OTelSum? {
        guard case .sum(let sum) = self else { return nil }
        return sum
    }

    package var asGauge: OTelGauge? {
        guard case .gauge(let gauge) = self else { return nil }
        return gauge
    }

    package var asHistogram: OTelHistogram? {
        guard case .histogram(let histogram) = self else { return nil }
        return histogram
    }

    package func assertIsCumulativeSumWithOneValue(_ value: OTelNumberDataPoint.Value, file: StaticString = #file, line: UInt = #line) {
        guard
            case .sum(let sum) = self,
            sum.monotonic,
            sum.aggregationTemporality == .cumulative,
            sum.points.count == 1,
            let point = sum.points.first
        else {
            XCTFail("Not cumulative sum with one point: \(self)", file: file, line: line)
            return
        }
        XCTAssertEqual(point.value, value, file: file, line: line)
    }

    package func assertIsGaugeWithOneValue(_ value: OTelNumberDataPoint.Value, file: StaticString = #file, line: UInt = #line) {
        guard
            case .gauge(let gauge) = self,
            gauge.points.count == 1,
            let point = gauge.points.first
        else {
            XCTFail("Not gauge with one point: \(self)", file: file, line: line)
            return
        }
        XCTAssertEqual(point.value, value, file: file, line: line)
    }

    package func assertIsCumulativeHistogramWith(count: Int, sum: Double, buckets: [OTelHistogramDataPoint.Bucket], file: StaticString = #file, line: UInt = #line) {
        guard
            case .histogram(let histogram) = self,
            histogram.aggregationTemporality == .cumulative,
            histogram.points.count == 1,
            let point = histogram.points.first
        else {
            XCTFail("Not cumulative histogram with one point: \(self)", file: file, line: line)
            return
        }

        XCTAssertEqual(point.count, UInt64(count), file: file, line: line)
        XCTAssertEqual(point.sum, sum, file: file, line: line)
        XCTAssertEqual(point.buckets, buckets, file: file, line: line)
    }
}
