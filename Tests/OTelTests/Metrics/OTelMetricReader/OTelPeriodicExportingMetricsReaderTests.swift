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
import NIOConcurrencyHelpers
@testable import OTel
@testable import OTelTesting
import XCTest

final class OTelPeriodicExportingMetricsReaderTests: XCTestCase {
    func test_normalBehavior_periodicallyExports() async throws {
        let clock = TestClock()
        let exporter = RecordingMetricExporter()
        let producer = MockMetricProducer()
        let reader = OTelPeriodicExportingMetricsReader(
            resource: .init(),
            producer: producer,
            exporter: exporter,
            configuration: .init(
                environment: .detected(),
                exportInterval: .seconds(1),
                exportTimeout: .milliseconds(100)
            ),
            clock: clock
        )
        _ = reader.description
        var sleepCalls = clock.sleepCalls.makeAsyncIterator()
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await reader.run()
            }

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the expected producer and exporter counts.
            producer.assert(produceCallCount: 0)
            exporter.assert(exportCallCount: 0, forceFlushCallCount: 0, shutdownCallCount: 0)

            // advance the clock for the tick.
            clock.advance(to: .seconds(1))

            // await sleep for export timeout and advance passed it.
            await sleepCalls.next()
            clock.advance(by: .milliseconds(200))

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the expected producer and exporter counts.
            producer.assert(produceCallCount: 1)
            exporter.assert(exportCallCount: 1, forceFlushCallCount: 0, shutdownCallCount: 0)

            // advance the clock for the tick.
            clock.advance(to: .seconds(2))

            // await sleep for export timeout and advance passed it.
            await sleepCalls.next()
            clock.advance(by: .milliseconds(200))

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the expected producer and exporter counts.
            producer.assert(produceCallCount: 2)
            exporter.assert(exportCallCount: 2, forceFlushCallCount: 0, shutdownCallCount: 0)

            group.cancelAll()
        }
    }

    func test_exportTakesLongerThanTimeout_logsWarning() async throws {
        let recordingLogHandler = RecordingLogHandler()
        LoggingSystem.bootstrapInternal { _ in recordingLogHandler }
        let clock = TestClock()
        let exporter = MockMetricExporter(behavior: .sleep)
        let producer = MockMetricProducer()
        let reader = OTelPeriodicExportingMetricsReader(
            resource: .init(),
            producer: producer,
            exporter: exporter,
            configuration: .init(
                environment: .detected(),
                exportInterval: .seconds(1),
                exportTimeout: .milliseconds(100)
            ),
            clock: clock
        )
        var sleepCalls = clock.sleepCalls.makeAsyncIterator()
        var warningLogs = recordingLogHandler.recordedLogMessageStream.filter { $0.level == .warning }.makeAsyncIterator()
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await reader.run()
            }

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the export cancellation and warning log counts.
            XCTAssertEqual(recordingLogHandler.warningCount, 0)
            XCTAssertEqual(exporter.cancellationCount.withLockedValue { $0 }, 0)

            // advance the clock for the tick.
            clock.advance(to: .seconds(1))

            // await sleep for export timeout and advance passed it.
            await sleepCalls.next()
            clock.advance(by: .milliseconds(200))
            _ = await warningLogs.next()

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the export cancellation and warning log counts.
            XCTAssertEqual(recordingLogHandler.warningCount, 1)
            XCTAssertEqual(exporter.cancellationCount.withLockedValue { $0 }, 1)

            // advance the clock for the tick.
            clock.advance(to: .seconds(2))

            // await sleep for export timeout and advance passed it.
            await sleepCalls.next()
            clock.advance(by: .milliseconds(200))
            _ = await warningLogs.next()

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the export cancellation and warning log counts.
            XCTAssertEqual(recordingLogHandler.warningCount, 2)
            XCTAssertEqual(exporter.cancellationCount.withLockedValue { $0 }, 2)

            group.cancelAll()
        }
    }

    func test_exportThrowsError_logsError() async throws {
        let recordingLogHandler = RecordingLogHandler()
        LoggingSystem.bootstrapInternal { _ in recordingLogHandler }
        let clock = TestClock()
        let exporter = MockMetricExporter(behavior: .throw)
        let producer = MockMetricProducer()
        let reader = OTelPeriodicExportingMetricsReader(
            resource: .init(),
            producer: producer,
            exporter: exporter,
            configuration: .init(
                environment: .detected(),
                exportInterval: .seconds(1),
                exportTimeout: .milliseconds(100)
            ),
            clock: clock
        )
        var sleepCalls = clock.sleepCalls.makeAsyncIterator()
        var errorLogs = recordingLogHandler.recordedLogMessageStream.filter { $0.level == .error }.makeAsyncIterator()
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await reader.run()
            }

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the export throw and error log counts.
            XCTAssertEqual(recordingLogHandler.errorCount, 0)
            XCTAssertEqual(exporter.throwCount.withLockedValue { $0 }, 0)

            // advance the clock for the tick.
            clock.advance(to: .seconds(1))

            // await sleep for export timeout.
            await sleepCalls.next()
            _ = await errorLogs.next()

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the export cancellation and error log counts.
            XCTAssertEqual(recordingLogHandler.errorCount, 1)
            XCTAssertEqual(exporter.throwCount.withLockedValue { $0 }, 1)

            // advance the clock for the tick.
            clock.advance(to: .seconds(2))

            // await sleep for export timeout and advance passed it.
            await sleepCalls.next()
            _ = await errorLogs.next()

            // await sleep for tick.
            await sleepCalls.next()

            // while the timer sequence is sleeping, check the export cancellation and error log counts.
            XCTAssertEqual(recordingLogHandler.errorCount, 2)
            XCTAssertEqual(exporter.throwCount.withLockedValue { $0 }, 2)

            group.cancelAll()
        }
    }

    func test_initalizer_usesContinuousClockByDefault() {
        let reader = OTelPeriodicExportingMetricsReader(
            resource: .init(),
            producer: MockMetricProducer(),
            exporter: RecordingMetricExporter(),
            configuration: .init(environment: .detected())
        )
        XCTAssert(type(of: reader.clock) == ContinuousClock.self)
    }
}

// MARK: - Helpers

final class MockMetricProducer: Sendable, OTelMetricProducer {
    let produceReturnValue = NIOLockedValueBox([OTelMetricPoint]())
    let produceCallCount = NIOLockedValueBox(0)
    func produce() -> [OTelMetricPoint] {
        produceCallCount.withLockedValue { $0 += 1 }
        return produceReturnValue.withLockedValue { $0 }
    }

    func assert(produceCallCount: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(self.produceCallCount.withLockedValue { $0 }, produceCallCount, file: file, line: line)
    }
}

final class MockMetricExporter: Sendable, OTelMetricExporter {
    struct MockError: Error {}

    enum Behavior {
        case sleep
        case `throw`
    }

    let behavior: Behavior

    let cancellationCount = NIOLockedValueBox(0)
    let throwCount = NIOLockedValueBox(0)

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func export(_ batch: some Collection<OTel.OTelResourceMetrics> & Sendable) async throws {
        switch behavior {
        case .sleep:
            try await withTaskCancellationHandler {
                while true {
                    try await Task.sleep(for: .seconds(60))
                }
            } onCancel: {
                cancellationCount.withLockedValue { $0 += 1 }
            }
        case .throw:
            throwCount.withLockedValue { $0 += 1 }
            throw MockError()
        }
    }

    func forceFlush() async throws { fatalError("not implemented") }

    func shutdown() async { fatalError("not implemented") }
}
