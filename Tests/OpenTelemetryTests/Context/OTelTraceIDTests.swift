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
import OTelTesting
import XCTest

final class OTelTraceIDTests: XCTestCase {
    func test_bytes_returnsUnderlyingBytesAsByteArray() {
        let traceID = OTelTraceID.oneToSixteen

        XCTAssertEqual(traceID.bytes, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
    }

    func test_hexBytes_returnsHexByteRepresentation() {
        let traceID = OTelTraceID.oneToSixteen

        XCTAssertEqual(
            traceID.hexBytes,
            [
                48, 49, 48, 50, 48, 51, 48, 52, 48, 53, 48, 54, 48, 55, 48, 56,
                48, 57, 48, 97, 48, 98, 48, 99, 48, 100, 48, 101, 48, 102, 49, 48,
            ]
        )
    }

    func test_description_returnsHexStringRepresentation() {
        let traceID = OTelTraceID.oneToSixteen

        XCTAssertEqual(traceID.description, "0102030405060708090a0b0c0d0e0f10")
    }

    func test_hash_createsUniqueHashValue() {
        let traceID1 = OTelTraceID.oneToSixteen
        let traceID2 = OTelTraceID(bytes: (17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32))

        XCTAssertNotEqual(traceID1.hashValue, traceID2.hashValue)
    }

    func test_equatable_equals() {
        let traceID1 = OTelTraceID.oneToSixteen
        let traceID2 = OTelTraceID.oneToSixteen

        XCTAssertEqual(traceID1, traceID2)
    }

    func test_equatable_notEquals() {
        let traceID1 = OTelTraceID.oneToSixteen
        let traceID2 = OTelTraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17))

        XCTAssertNotEqual(traceID1, traceID2)
    }
}
