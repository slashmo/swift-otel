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
import ServiceContextModule
import XCTest

final class SpanContextTests: XCTestCase {
    func test_storedInServiceContext() {
        let spanContext = OTel.SpanContext(
            traceID: OTel.TraceID(bytes: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
            spanID: OTel.SpanID(bytes: (0, 0, 0, 0, 0, 0, 0, 2)),
            parentSpanID: OTel.SpanID(bytes: (0, 0, 0, 0, 0, 0, 0, 1)),
            traceFlags: .sampled,
            traceState: OTel.TraceState([(vendor: "rojo", value: "00f067aa0ba902b7")]),
            isRemote: false
        )

        var context = ServiceContext.topLevel
        XCTAssertNil(context.spanContext)

        context.spanContext = spanContext
        XCTAssertEqual(context.spanContext, spanContext)

        context.spanContext = nil
        XCTAssertNil(context.spanContext)
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