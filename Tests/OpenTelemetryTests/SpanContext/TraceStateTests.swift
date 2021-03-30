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
import XCTest

final class TraceStateTests: XCTestCase {
    func test_equatable() {
        let traceState1 = OTel.TraceState([
            (vendor: "1", value: "1"),
            (vendor: "2", value: "2"),
            (vendor: "3", value: "3"),
        ])
        let traceState2 = OTel.TraceState([
            (vendor: "1", value: "1"),
            (vendor: "2", value: "2"),
            (vendor: "3", value: "3"),
        ])
        let traceState3 = OTel.TraceState([
            (vendor: "3", value: "3"),
            (vendor: "2", value: "2"),
            (vendor: "1", value: "1"),
        ])

        XCTAssertEqual(traceState1, traceState2)
        XCTAssertNotEqual(traceState2, traceState3)
        XCTAssertNotEqual(traceState1, nil)
    }
}
