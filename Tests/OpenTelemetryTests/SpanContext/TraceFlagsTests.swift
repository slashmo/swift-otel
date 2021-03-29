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

final class TraceFlagsTests: XCTestCase {
    func test_sampledFlag() {
        XCTAssertTrue(OTel.TraceFlags.sampled.contains(.sampled))

        XCTAssertFalse(OTel.TraceFlags(rawValue: 2).contains(.sampled))

        XCTAssertTrue(OTel.TraceFlags(rawValue: 3).contains(.sampled))
    }
}
