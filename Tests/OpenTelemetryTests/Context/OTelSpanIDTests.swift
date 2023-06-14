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

final class OTelSpanIDTests: XCTestCase {
    func test_bytes_returnsUnderlyingBytesAsByteArray() {
        let spanID = OTelSpanID.oneToEight

        XCTAssertEqual(spanID.bytes, [1, 2, 3, 4, 5, 6, 7, 8])
    }

    func test_hexBytes_returnsHexByteRepresentation() {
        let spanID = OTelSpanID.oneToEight

        XCTAssertEqual(spanID.hexBytes, [48, 49, 48, 50, 48, 51, 48, 52, 48, 53, 48, 54, 48, 55, 48, 56])
    }

    func test_description_returnsHexStringRepresentation() {
        let spanID = OTelSpanID.oneToEight

        XCTAssertEqual(spanID.description, "0102030405060708")
    }

    func test_hash_createsUniqueHashValue() {
        let spanID1 = OTelSpanID.oneToEight
        let spanID2 = OTelSpanID(bytes: (9, 10, 11, 12, 13, 14, 15, 16))

        XCTAssertNotEqual(spanID1.hashValue, spanID2.hashValue)
    }

    func test_equatable_equals() {
        let spanID1 = OTelSpanID.oneToEight
        let spanID2 = OTelSpanID.oneToEight

        XCTAssertEqual(spanID1, spanID2)
    }

    func test_equatable_notEquals() {
        let spanID1 = OTelSpanID.oneToEight
        let spanID2 = OTelSpanID(bytes: (1, 2, 3, 4, 5, 6, 7, 9))

        XCTAssertNotEqual(spanID1, spanID2)
    }
}
