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

final class OTelTraceFlagsTests: XCTestCase {
    func test_sampled() {
        XCTAssertEqual(OTelTraceFlags.sampled.rawValue, 1)

        XCTAssertEqual(OTelTraceFlags([]).rawValue, 0)

        XCTAssertTrue(OTelTraceFlags(rawValue: 1).contains(.sampled))
    }
}
