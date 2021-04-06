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

import CoreBaggage
@testable import OpenTelemetry
import XCTest

final class SpanContextTests: XCTestCase {
    func test_storedInBaggage() {
        let spanContext = OTel.SpanContext(
            traceID: OTel.TraceID(bytes: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
            spanID: OTel.SpanID(bytes: (0, 0, 0, 0, 0, 0, 0, 2)),
            parentSpanID: OTel.SpanID(bytes: (0, 0, 0, 0, 0, 0, 0, 1)),
            traceFlags: .sampled,
            traceState: OTel.TraceState([(vendor: "rojo", value: "00f067aa0ba902b7")]),
            isRemote: false
        )

        var baggage = Baggage.topLevel
        XCTAssertNil(baggage.spanContext)

        baggage.spanContext = spanContext
        XCTAssertEqual(baggage.spanContext, spanContext)

        baggage.spanContext = nil
        XCTAssertNil(baggage.spanContext)
    }

    func test_stringConvertible_notSampled() {
        let spanContext = OTel.SpanContext.stub()

        XCTAssertEqual(spanContext.description, "\(OTel.TraceID.stub)-\(OTel.SpanID.stub)-00")
    }

    func test_stringConvertible_sampled() {
        let spanContext = OTel.SpanContext.stub(traceFlags: .sampled)

        XCTAssertEqual(spanContext.description, "\(OTel.TraceID.stub)-\(OTel.SpanID.stub)-01")
    }
}
