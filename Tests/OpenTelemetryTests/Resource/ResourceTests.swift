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

final class ResourceTests: XCTestCase {
    func test_mergingTwoResources() {
        let resourceA = OTel.Resource(attributes: ["a": "test"])
        let resourceB = OTel.Resource(attributes: ["b": "test"])

        let resourceC = resourceA.merging(resourceB)

        XCTAssertEqual(resourceC.attributes.count, 2, "Merged resource should contain both attributes.")
    }
}
