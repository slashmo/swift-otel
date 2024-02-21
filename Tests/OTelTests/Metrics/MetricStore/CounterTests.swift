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
import OTelTesting
import XCTest

final class CounterTests: XCTestCase {
    func test_increment() {
        let counter = Counter(name: "my_counter", attributes: [])
        counter.assertStateEquals(integerPart: 0, doublePart: 0)

        counter.increment(by: Int64(0))
        counter.assertStateEquals(integerPart: 0, doublePart: 0)

        counter.increment()
        counter.assertStateEquals(integerPart: 1, doublePart: 0)

        counter.increment(by: Int64(1))
        counter.assertStateEquals(integerPart: 2, doublePart: 0)

        counter.increment(by: Double(1.5))
        counter.assertStateEquals(integerPart: 2, doublePart: 1.5)

        counter.increment(by: Int64(2))
        counter.assertStateEquals(integerPart: 4, doublePart: 1.5)

        counter.reset()
        counter.assertStateEquals(integerPart: 0, doublePart: 0)
    }

    func test_increment_concurrent() async {
        let counter = Counter(name: "my_counter", attributes: [])
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 100_000 {
                group.addTask {
                    counter.increment(by: Double(1))
                }
            }
            for _ in 0 ..< 100_000 {
                group.addTask {
                    counter.increment(by: Int64(1))
                }
            }
        }
        counter.assertStateEquals(integerPart: 100_000, doublePart: 100_000)
    }
}
