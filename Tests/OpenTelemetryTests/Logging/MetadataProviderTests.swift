//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import InstrumentationBaggage
@testable import Logging
@testable import OpenTelemetry
import XCTest

final class MetadataProviderTests: XCTestCase {
    func test_providesMetadataFromSpanContext_withDefaultLabels() throws {
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            throw XCTSkip("Task locals are not supported on this platform.")
        }

        let stream = InterceptingStream()
        var logger = Logger(label: "test")
        logger.handler = StreamLogHandler(label: "test", stream: stream, metadataProvider: .otel)

        let spanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            traceFlags: .sampled,
            isRemote: true
        )

        var baggage = Baggage.topLevel
        baggage.spanContext = spanContext
        Baggage.$current.withValue(baggage) {
            logger.info("This is a test message", metadata: ["explicit": "42"])
        }

        XCTAssertEqual(stream.strings.count, 1)
        let message = try XCTUnwrap(stream.strings.first)

        XCTAssertTrue(message.contains("span-id=\(spanContext.spanID)"))
        XCTAssertTrue(message.contains("trace-id=\(spanContext.traceID)"))
        XCTAssertTrue(message.contains("explicit=42"))
        XCTAssertTrue(message.contains("This is a test message"))
    }

    func test_providesMetadataFromSpanContext_withCustomLabels() throws {
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            throw XCTSkip("Task locals are not supported on this platform.")
        }

        let stream = InterceptingStream()
        var logger = Logger(label: "test")
        let metadataProvider = Logger.MetadataProvider.otel(traceIDKey: "custom_trace_id", spanIDKey: "custom_span_id")
        logger.handler = StreamLogHandler(label: "test", stream: stream, metadataProvider: metadataProvider)

        let spanContext = OTel.SpanContext(
            traceID: .random(),
            spanID: .random(),
            traceFlags: .sampled,
            isRemote: true
        )

        var baggage = Baggage.topLevel
        baggage.spanContext = spanContext
        Baggage.$current.withValue(baggage) {
            logger.info("This is a test message", metadata: ["explicit": "42"])
        }

        XCTAssertEqual(stream.strings.count, 1)
        let message = try XCTUnwrap(stream.strings.first)

        XCTAssertTrue(message.contains("custom_span_id=\(spanContext.spanID)"))
        XCTAssertTrue(message.contains("custom_trace_id=\(spanContext.traceID)"))
        XCTAssertTrue(message.contains("explicit=42"))
        XCTAssertTrue(message.contains("This is a test message"))
    }

    func test_doesNotProvideMetadataWithoutSpanContext() throws {
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            throw XCTSkip("Task locals are not supported on this platform.")
        }

        let stream = InterceptingStream()
        var logger = Logger(label: "test")
        let metadataProvider = Logger.MetadataProvider.otel
        logger.handler = StreamLogHandler(label: "test", stream: stream, metadataProvider: metadataProvider)

        logger.info("This is a test message", metadata: ["explicit": "42"])

        XCTAssertEqual(stream.strings.count, 1)
        let message = try XCTUnwrap(stream.strings.first)

        XCTAssertFalse(message.contains("trace-id"))
        XCTAssertFalse(message.contains("span-id"))
        XCTAssertTrue(message.contains("explicit=42"))
        XCTAssertTrue(message.contains("This is a test message"))
    }
}

final class InterceptingStream: TextOutputStream {
    var interceptedText: String?
    var strings = [String]()

    func write(_ string: String) {
        strings.append(string)
        interceptedText = (interceptedText ?? "") + string
    }
}

extension InterceptingStream: @unchecked Sendable {}
