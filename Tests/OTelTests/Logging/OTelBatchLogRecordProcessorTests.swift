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
@_spi(Logging) @_spi(Testing) import OTel
import OTelTesting
import XCTest

final class OTelBatchLogRecordProcessorTests: XCTestCase {
    private let resource = OTelResource(attributes: ["service.name": "log_batch_processor_tests"])

    func testBatchLogProcessorAccumulatesUntilQueueSize() async throws {
        let exporter = OTelInMemoryLogRecordExporter()
        let batchProcessor = OTelBatchLogRecordProcessor(
            exporter: exporter,
            configuration: OTelBatchLogRecordProcessorConfiguration(
                environment: .detected(),
                maximumQueueSize: 5,
                scheduleDelay: .seconds(60) // Should never trigger
            )
        )

        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask(operation: batchProcessor.run)

            let logHandler = OTelLogHandler(processor: batchProcessor, logLevel: .debug, resource: resource)
            var recordIterator = exporter.didRecordBatch.makeAsyncIterator()
            let logger = Logger(label: "Test", logHandler)

            for i in 1...4 {
                logger.info("\(i)")
            }

            // TODO: Records are emitted asynchronously, so checking this without delay
            // is not representative
            XCTAssertEqual(exporter.records, [])

            logger.info("5")

            // Records are emitted asynchronously, so let's wait for that to happen
            let records = await recordIterator.next()
            guard records == 5 else {
                XCTFail("Expected to record 5 entities, recorded \(records ?? 0)")
                return
            }
            XCTAssertEqual(exporter.records.count, 5)

            taskGroup.cancelAll()
        }
    }

    func testBatchLogProcessorEmitsEarlyAfterDelay() async throws {
        let exporter = OTelInMemoryLogRecordExporter()
        let clock = TestClock()
        var sleeps = clock.sleepCalls.makeAsyncIterator()
        let batchProcessor = OTelBatchLogRecordProcessor(
            exporter: exporter,
            configuration: OTelBatchLogRecordProcessorConfiguration(
                environment: .detected(),
                maximumQueueSize: 100,
                scheduleDelay: .milliseconds(10)
            ),
            clock: clock
        )

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask(operation: batchProcessor.run)
            var iterator = exporter.didRecordBatch.makeAsyncIterator()

            let logHandler = OTelLogHandler(
                processor: batchProcessor,
                logLevel: .debug,
                resource: resource
            )
            let logger = Logger(label: "Test", logHandler)

            for i in 1...4 {
                logger.info("\(i)")
            }

            // Records are emitted asynchronously, so checking this without a real delay
            // is not representative.
            // You also can't suspend until a log has reached the processor - which
            // makes this test otherwise infeasible
            try await Task.sleep(for: .milliseconds(100))
            XCTAssertEqual(exporter.records.count, 0)

            await sleeps.next()
            clock.advance(by: .milliseconds(10))
            await sleeps.next()

            // Records should update after delay
            let records = await iterator.next()
            guard records == 4 else {
                XCTFail("Expected to record 4 entities, recorded \(records ?? 0)")
                return
            }
            XCTAssertEqual(exporter.records.count, 4)

            taskGroup.cancelAll()
        }
    }

    func testBatchLogProcessorForceFlushEmitsEarly() async throws {
        let exporter = OTelInMemoryLogRecordExporter()
        let batchProcessorClock = TestClock()
        let batchProcessor = OTelBatchLogRecordProcessor(
            exporter: exporter,
            configuration: OTelBatchLogRecordProcessorConfiguration(
                environment: .detected(),
                maximumQueueSize: 5,
                scheduleDelay: .seconds(60) // Should never trigger
            ),
            clock: batchProcessorClock
        )

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask(operation: batchProcessor.run)

            let logHandler = OTelLogHandler(
                processor: batchProcessor,
                logLevel: .debug,
                resource: resource
            )
            let logger = Logger(label: "Test", logHandler)

            for i in 1...4 {
                logger.info("\(i)")
            }

            // Without this, the Logger intermittendly hasn't reported the logs to the processor
            try await Task.sleep(for: .milliseconds(100))

            // Nothing should be emitted
            // TODO: Records are emitted asynchronously, so this check checking is not representative
            XCTAssertEqual(exporter.records.count, 0)

            try await batchProcessor.forceFlush()
            XCTAssertEqual(exporter.records.count, 4)

            taskGroup.cancelAll()
        }
    }

    func testBatchLogProcessorCancelsSlowExports() async throws {
        let exporterClock = TestClock()
        let batchProcessorClock = TestClock()
        let exporter = OTelSlowLogRecordExporter(delay: .seconds(5), clock: exporterClock)
        let batchProcessor = OTelBatchLogRecordProcessor(
            exporter: exporter,
            configuration: OTelBatchLogRecordProcessorConfiguration(
                environment: .detected(),
                maximumQueueSize: 5,
                scheduleDelay: .seconds(6), // Should never trigger
                exportTimeout: .seconds(1)
            ),
            clock: batchProcessorClock
        )

        let logHandler = OTelLogHandler(
            processor: batchProcessor,
            logLevel: .debug,
            resource: resource
        )
        let logger = Logger(label: "Test", logHandler)

        for i in 1...5 {
            logger.info("\(i)")
        }

        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask(operation: batchProcessor.run)
            taskGroup.addTask {
                try await batchProcessor.forceFlush()
            }

            batchProcessorClock.advance(by: .seconds(1))
            taskGroup.cancelAll()
        }

        XCTAssertEqual(exporter.records, [])
        XCTAssertEqual(exporter.cancelCount, 1)
    }
}
