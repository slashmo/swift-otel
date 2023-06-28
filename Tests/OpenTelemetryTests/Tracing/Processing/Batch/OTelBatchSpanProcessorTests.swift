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

import Logging
@testable import OpenTelemetry
import OTelTesting
import XCTest

final class OTelBatchSpanProcessorTests: XCTestCase {
    override func setUp() {
        LoggingSystem.bootstrapInternal(logLevel: .trace)
    }

    // MARK: - onEnd

    func test_onEnd_withEmptyQueue_addsSpanToQueue() async throws {
        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: [:],
            maximumQueueSize: 2,
            scheduleDelayInMilliseconds: 10,
            maximumExportBatchSize: 2
        )
        let exporter = OTelStreamingSpanExporter()
        let processor = OTelBatchSpanProcessor(configuration: configuration, exportingTo: exporter)

        let span = OTelFinishedSpan.stub(operationName: "test")
        await processor.onEnd(span)

        do {
            let queue = await processor.queue
            XCTAssertEqual(queue.map(\.operationName), ["test"])
        }

        var batchesIterator = await exporter.batches.makeAsyncIterator()
        guard let batch = await batchesIterator.next() else {
            XCTFail()
            return
        }
        XCTAssertEqual(batch.map(\.operationName), ["test"])

        do {
            let queue = await processor.queue
            XCTAssertTrue(queue.isEmpty)
        }
    }

    func test_onEnd_withNonEmptyQueue_appendsSpanToQueue() async {
        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: [:],
            maximumQueueSize: 3,
            scheduleDelayInMilliseconds: 10,
            maximumExportBatchSize: 3
        )
        let exporter = OTelStreamingSpanExporter()
        let processor = OTelBatchSpanProcessor(configuration: configuration, exportingTo: exporter)
        let span1 = OTelFinishedSpan.stub(operationName: "span1")
        await processor.onEnd(span1)

        let span2 = OTelFinishedSpan.stub(operationName: "span2")
        await processor.onEnd(span2)

        do {
            let queue = await processor.queue
            XCTAssertEqual(queue.map(\.operationName), ["span1", "span2"])
        }

        var batchesIterator = await exporter.batches.makeAsyncIterator()
        guard let batch = await batchesIterator.next() else {
            XCTFail()
            return
        }
        XCTAssertEqual(batch.map(\.operationName), ["span1", "span2"])

        do {
            let queue = await processor.queue
            XCTAssertTrue(queue.isEmpty)
        }
    }

    func test_onEnd_completelyFillingQueue_exportsBatchAheadOfTime() async throws {
        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: [:],
            maximumQueueSize: 2,
            maximumExportBatchSize: 2
        )
        let exporter = OTelStreamingSpanExporter()
        let processor = OTelBatchSpanProcessor(configuration: configuration, exportingTo: exporter)
        let span1 = OTelFinishedSpan.stub(operationName: "span1")
        await processor.onEnd(span1)

        do {
            let queue = await processor.queue
            XCTAssertEqual(queue.map(\.operationName), ["span1"])
        }

        let span2 = OTelFinishedSpan.stub(operationName: "span2")
        await processor.onEnd(span2)

        var batchesIterator = await exporter.batches.makeAsyncIterator()
        guard let batch = await batchesIterator.next() else {
            XCTFail()
            return
        }
        XCTAssertEqual(batch.map(\.operationName), ["span1", "span2"])

        do {
            let queue = await processor.queue
            XCTAssertTrue(queue.isEmpty)
        }
    }

    func test_onEnd_whenGoingPastExportTimeout_cancelsExport() async {
        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: [:],
            maximumQueueSize: 2,
            maximumExportBatchSize: 2,
            exportTimeoutInMilliseconds: 1
        )
        let exporter = OTelStreamingSpanExporter(exportDelayInNanoseconds: 1_000_000_000)
        let processor = OTelBatchSpanProcessor(configuration: configuration, exportingTo: exporter)
        let span1 = OTelFinishedSpan.stub(operationName: "span1")
        await processor.onEnd(span1)

        do {
            let queue = await processor.queue
            XCTAssertEqual(queue.map(\.operationName), ["span1"])
        }

        let span2 = OTelFinishedSpan.stub(operationName: "span2")
        await processor.onEnd(span2)

        var errorsIterator = await exporter.errors.makeAsyncIterator()
        guard let error = await errorsIterator.next() else {
            XCTFail()
            return
        }
        XCTAssertTrue(error is CancellationError)

        do {
            let queue = await processor.queue
            XCTAssertTrue(queue.isEmpty)
        }
    }

    // MARK: - forceFlush

    func test_forceFlush_withNonEmptyQueue_exportsBatchAheadOfTime() async throws {
        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: [:],
            maximumQueueSize: 10 /* high enough to not cause immediate export */,
            scheduleDelayInMilliseconds: 1000 /* high enough to not cause scheduled export */,
            maximumExportBatchSize: 2
        )
        let exporter = OTelStreamingSpanExporter()
        let processor = OTelBatchSpanProcessor(configuration: configuration, exportingTo: exporter)

        let span1 = OTelFinishedSpan.stub(operationName: "span1")
        let span2 = OTelFinishedSpan.stub(operationName: "span2")
        let span3 = OTelFinishedSpan.stub(operationName: "span3")
        let span4 = OTelFinishedSpan.stub(operationName: "span4")
        let span5 = OTelFinishedSpan.stub(operationName: "span5")

        for span in [span1, span2, span3, span4, span5] {
            await processor.onEnd(span)
        }

        do {
            let queue = await processor.queue
            XCTAssertEqual(queue.map(\.operationName), ["span1", "span2", "span3", "span4", "span5"])
        }

        try await processor.forceFlush()

        var batchesIterator = await exporter.batches.makeAsyncIterator()
        guard let batch1 = await batchesIterator.next(),
              let batch2 = await batchesIterator.next(),
              let batch3 = await batchesIterator.next()
        else {
            XCTFail()
            return
        }

        let batches = [batch1, batch2, batch3]

        XCTAssertTrue(batches.contains(where: { $0.map(\.operationName) == ["span1", "span2"] }))
        XCTAssertTrue(batches.contains(where: { $0.map(\.operationName) == ["span3", "span4"] }))
        XCTAssertTrue(batches.contains(where: { $0.map(\.operationName) == ["span5"] }))

        do {
            let queue = await processor.queue
            print(queue.count)
            XCTAssertTrue(queue.isEmpty)
        }
    }

    // MARK: - shutDown

    func test_shutDown_withNonEmptyQueue_forceFlushesAndShutsDownExporter() async throws {
        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: [:],
            maximumQueueSize: 10 /* high enough to not cause immediate export */,
            scheduleDelayInMilliseconds: 1000 /* high enough to not cause scheduled export */,
            maximumExportBatchSize: 1
        )
        let exporter = OTelStreamingSpanExporter()
        let processor = OTelBatchSpanProcessor(configuration: configuration, exportingTo: exporter)

        let span1 = OTelFinishedSpan.stub(operationName: "span1")
        let span2 = OTelFinishedSpan.stub(operationName: "span2")
        await processor.onEnd(span1)
        await processor.onEnd(span2)

        do {
            let queue = await processor.queue
            XCTAssertEqual(queue.map(\.operationName), ["span1", "span2"])
        }

        try await processor.shutdown()

        let numberOfShutdowns = await exporter.numberOfShutdowns
        XCTAssertEqual(numberOfShutdowns, 1)

        var batchesIterator = await exporter.batches.makeAsyncIterator()
        guard let batch1 = await batchesIterator.next(),
              let batch2 = await batchesIterator.next()
        else {
            XCTFail()
            return
        }

        let batches = [batch1, batch2]

        XCTAssertTrue(batches.contains(where: { $0.map(\.operationName) == ["span1"] }))
        XCTAssertTrue(batches.contains(where: { $0.map(\.operationName) == ["span2"] }))

        do {
            let queue = await processor.queue
            print(queue.count)
            XCTAssertTrue(queue.isEmpty)
        }
    }
}
