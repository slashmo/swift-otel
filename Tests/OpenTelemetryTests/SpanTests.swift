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

@testable import Logging
@testable import OpenTelemetry
import Tracing
import XCTest

final class SpanTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        LoggingSystem.bootstrapInternal {
            var handler = StreamLogHandler.standardOutput(label: $0)
            handler.logLevel = .debug
            return handler
        }
    }

    func test_ignoresRepeatedCallsToEnd() {
        let span = OTel.Tracer.Span(
            operationName: #function,
            baggage: .topLevel,
            kind: .internal,
            startTime: .now(),
            attributes: [:],
            logger: Logger(label: #function)
        )

        let endTime = DispatchWallTime.now()
        span.end(at: endTime)

        XCTAssertEqual(span.endTime, endTime)

        span.end()

        XCTAssertEqual(span.endTime, endTime)
    }

    func test_recordsErrorAsEvent() {
        let span = OTel.Tracer.Span(
            operationName: #function,
            baggage: .topLevel,
            kind: .internal,
            startTime: .now(),
            attributes: [:],
            logger: Logger(label: #function)
        )

        span.recordError(EnumError.some)

        XCTAssertEqual(span.events.count, 1)
        XCTAssertEqual(span.events[0].name, "exception")
        XCTAssertEqual(span.events[0].attributes["exception.type"]?.toSpanAttribute(), "EnumError")
        XCTAssertEqual(span.events[0].attributes["exception.message"]?.toSpanAttribute(), "some")

        span.recordError(StructError(description: "this is a severe test error!"))

        XCTAssertEqual(span.events.count, 2)
        XCTAssertEqual(span.events[1].name, "exception")
        XCTAssertEqual(span.events[1].attributes["exception.type"]?.toSpanAttribute(), "StructError")
        XCTAssertEqual(span.events[1].attributes["exception.message"]?.toSpanAttribute(), "this is a severe test error!")
    }
}

private enum EnumError: Error {
    case some
}

private struct StructError: Error, CustomStringConvertible {
    let description: String
}
