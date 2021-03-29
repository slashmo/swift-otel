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

final class SpanIDTests: XCTestCase {
    func test_describedAsLowercaseHexString() {
        let spanID = OTel.SpanID(bytes: (9, 10, 11, 12, 13, 14, 15, 16))

        XCTAssertEqual(spanID.bytes, [9, 10, 11, 12, 13, 14, 15, 16])
        XCTAssertEqual(spanID.description, "090a0b0c0d0e0f10")
    }

    func test_equatable() {
        let spanID1 = OTel.SpanID(bytes: (9, 10, 11, 12, 13, 14, 15, 16))
        let spanID2 = OTel.SpanID(bytes: (9, 10, 11, 12, 13, 14, 15, 16))
        let spanID3 = OTel.SpanID(bytes: (9, 10, 11, 12, 13, 14, 15, 10))

        XCTAssertEqual(spanID1, spanID2)
        XCTAssertNotEqual(spanID2, spanID3)
    }

    func test_hashable() {
        let spanID1 = OTel.SpanID(bytes: (0, 0, 0, 0, 0, 0, 0, 1))
        let spanID2 = OTel.SpanID(bytes: (0, 0, 0, 0, 0, 0, 0, 2))
        let spanID3 = OTel.SpanID(bytes: (0, 0, 0, 0, 0, 0, 0, 3))

        let spanIDs = Set([spanID1, spanID2, spanID3])

        XCTAssertEqual(spanIDs.count, 3)
    }
}
