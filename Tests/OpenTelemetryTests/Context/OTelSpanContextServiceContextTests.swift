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

@testable import OpenTelemetry
import ServiceContextModule
import XCTest

final class OTelSpanContextServiceContextTests: XCTestCase {
    func test_spanContext_storedInsideServiceContext() {
        let spanContext = OTelSpanContext(
            traceID: OTelTraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
            spanID: OTelSpanID(bytes: (1, 2, 3, 4, 5, 6, 7, 8)),
            parentSpanID: nil,
            traceFlags: .sampled,
            traceState: nil,
            isRemote: false
        )

        var serviceContext = ServiceContext.topLevel
        XCTAssertTrue(serviceContext.isEmpty)
        XCTAssertNil(serviceContext.spanContext)

        serviceContext.spanContext = spanContext
        XCTAssertEqual(serviceContext.count, 1)

        XCTAssertEqual(serviceContext.spanContext, spanContext)
    }
}
