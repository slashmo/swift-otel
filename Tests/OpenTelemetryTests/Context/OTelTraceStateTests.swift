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

import OpenTelemetry
import XCTest

final class OTelTraceStateTests: XCTestCase {
    func test_equatable_equals() {
        XCTAssertEqual(
            OTelTraceState(storage: [(vendor: "1", value: "1"), (vendor: "2", value: "2")]),
            OTelTraceState(storage: [(vendor: "1", value: "1"), (vendor: "2", value: "2")])
        )
    }

    func test_equatable_notEquals_differentCount() {
        XCTAssertNotEqual(
            OTelTraceState(storage: [(vendor: "1", value: "1"), (vendor: "2", value: "2")]),
            OTelTraceState(storage: [(vendor: "1", value: "1")])
        )
    }

    func test_equatable_notEquals_differentVendors() {
        XCTAssertNotEqual(
            OTelTraceState(storage: [(vendor: "1", value: "1")]),
            OTelTraceState(storage: [(vendor: "2", value: "1")])
        )
    }

    func test_equatable_notEquals_differentValues() {
        XCTAssertNotEqual(
            OTelTraceState(storage: [(vendor: "1", value: "1")]),
            OTelTraceState(storage: [(vendor: "1", value: "2")])
        )
    }

    func test_description_keepsOrder() {
        let traceState = OTelTraceState(storage: [
            (vendor: "3", value: "3"),
            (vendor: "2", value: "2"),
            (vendor: "1", value: "1"),
        ])

        XCTAssertEqual(traceState.description, "3=3,2=2,1=1")
    }
}
