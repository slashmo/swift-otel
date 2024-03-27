//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@testable import Logging
@_spi(Logging) import OTel
import OTelTesting
import XCTest

final class OTelLogHandlerTests: XCTestCase {
    func test_log_withoutMetadata_forwardsLogEntryToProcessor() {
        let processor = OTelInMemoryLogRecordProcessor()
        let logger = Logger(label: #function) { _ in
            OTelLogHandler(processor: processor, logLevel: .info, metadata: [:], nanosecondsSinceEpoch: { 42 })
        }

        logger.info("🏎️")

        XCTAssertEqual(processor.records, [
            OTelLogRecord(body: "🏎️", level: .info, metadata: nil, timeNanosecondsSinceEpoch: 42),
        ])
    }

    func test_log_withLoggerMetadata_includesMetadataInLogRecord() {
        let processor = OTelInMemoryLogRecordProcessor()
        var logger = Logger(label: #function) { _ in
            OTelLogHandler(processor: processor, logLevel: .info, metadata: [:], nanosecondsSinceEpoch: { 42 })
        }
        logger[metadataKey: "logger"] = "42"

        logger.info("🏎️")

        XCTAssertEqual(processor.records, [
            OTelLogRecord(body: "🏎️", level: .info, metadata: ["logger": "42"], timeNanosecondsSinceEpoch: 42),
        ])
    }

    func test_log_withHandlerMetadata_includesMetadataInLogRecord() {
        let processor = OTelInMemoryLogRecordProcessor()
        let logger = Logger(label: #function) { _ in
            OTelLogHandler(
                processor: processor,
                logLevel: .info,
                metadata: ["handler": "42"],
                nanosecondsSinceEpoch: { 42 }
            )
        }

        logger.info("🏎️")

        XCTAssertEqual(processor.records, [
            OTelLogRecord(body: "🏎️", level: .info, metadata: ["handler": "42"], timeNanosecondsSinceEpoch: 42),
        ])
    }

    func test_log_withHandlerAndLoggerMetadata_overridesHandlerWithLoggerMetadata() {
        let processor = OTelInMemoryLogRecordProcessor()
        var logger = Logger(label: #function) { _ in
            OTelLogHandler(
                processor: processor,
                logLevel: .info,
                metadata: ["shared": "handler"],
                nanosecondsSinceEpoch: { 42 }
            )
        }
        logger[metadataKey: "shared"] = "logger"

        logger.info("🏎️")

        XCTAssertEqual(processor.records, [
            OTelLogRecord(body: "🏎️", level: .info, metadata: ["shared": "logger"], timeNanosecondsSinceEpoch: 42),
        ])
    }

    func test_log_withLoggerAndAdHocMetadata_overridesLoggerWithAdHocMetadata() {
        let processor = OTelInMemoryLogRecordProcessor()
        var logger = Logger(label: #function) { _ in
            OTelLogHandler(processor: processor, logLevel: .info, metadata: [:], nanosecondsSinceEpoch: { 42 })
        }
        logger[metadataKey: "shared"] = "logger"

        logger.info("🏎️", metadata: ["shared": "ad-hoc"])

        XCTAssertEqual(processor.records, [
            OTelLogRecord(body: "🏎️", level: .info, metadata: ["shared": "ad-hoc"], timeNanosecondsSinceEpoch: 42),
        ])
    }

    func test_loggerMetadataProxiesToHandlerMetadata() throws {
        let processor = OTelInMemoryLogRecordProcessor()
        var logger = Logger(label: #function) { _ in
            OTelLogHandler(processor: processor, logLevel: .info, metadata: ["shared": "handler"])
        }

        logger[metadataKey: "shared"] = "logger"
        let handler = try XCTUnwrap(logger.handler as? OTelLogHandler)

        XCTAssertEqual(handler[metadataKey: "shared"], "logger")

        logger.info("🏎️")

        XCTAssertEqual(try XCTUnwrap(processor.records.first).metadata, ["shared": "logger"])
    }
}
