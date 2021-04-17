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

import NIO
@testable import OpenTelemetry
import XCTest

final class BatchSpanProcessorTests: XCTestCase {
    private var eventLoopGroup: EventLoopGroup!

    override func setUpWithError() throws {
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    override func tearDownWithError() throws {
        try eventLoopGroup.syncShutdownGracefully()
    }

    func test_doesNotInvokeExporterWithEmptyBatch() throws {
        let exporter = InMemorySpanExporter(eventLoopGroup: eventLoopGroup)

        let processor = OTel.BatchSpanProcessor(
            interval: .zero,
            exportingTo: exporter,
            eventLoopGroup: eventLoopGroup
        )

        try eventLoopGroup.next().scheduleTask(in: .microseconds(100)) {}.futureResult.wait()
        try exporter.shutdownGracefully().wait()
        try processor.shutdownGracefully().wait()

        XCTAssertEqual(exporter.numberOfExports, 0)
    }

    func test_exportsSingleBatch() throws {
        let span1 = try recordedSpan()
        let span2 = try recordedSpan()
        let span3 = try recordedSpan()

        let exporter = AwaitingSpanExporter(expectedNumberOfSpans: 3, eventLoopGroup: eventLoopGroup)
        let processor = OTel.BatchSpanProcessor(
            interval: .milliseconds(10),
            exportingTo: exporter,
            eventLoopGroup: eventLoopGroup
        )

        for span in [span1, span2, span3] {
            processor.processEndedSpan(span)
        }

        try exporter.shutdownGracefully().wait()

        XCTAssertEqual(exporter.spans.count, 3, "All 3 spans should have been exported.")
        XCTAssertEqual(exporter.numberOfBatches, 1, "All 3 spans should have been exported in one batch.")

        XCTAssertEqual(exporter.spans[0].context.spanID, span1.context.spanID)
        XCTAssertEqual(exporter.spans[1].context.spanID, span2.context.spanID)
        XCTAssertEqual(exporter.spans[2].context.spanID, span3.context.spanID)

        try processor.shutdownGracefully().wait()
    }

    func test_exportsMultipleBatches() throws {
        let span1 = try recordedSpan()
        let span2 = try recordedSpan()
        let span3 = try recordedSpan()
        let span4 = try recordedSpan()
        let span5 = try recordedSpan()
        let span6 = try recordedSpan()
        let span7 = try recordedSpan()

        let exporter = AwaitingSpanExporter(expectedNumberOfSpans: 7, eventLoopGroup: eventLoopGroup)
        let processor = OTel.BatchSpanProcessor(
            maxBatchSize: 3,
            interval: .zero,
            exportingTo: exporter,
            eventLoopGroup: eventLoopGroup
        )

        for span in [span1, span2, span3, span4, span5, span6, span7] {
            processor.processEndedSpan(span)
        }

        try exporter.shutdownGracefully().wait()

        XCTAssertEqual(exporter.spans.count, 7, "All 7 spans should have been exported.")
        XCTAssertEqual(exporter.numberOfBatches, 3, "The 7 spans should have been exported in 3 batches.")

        XCTAssertEqual(exporter.spans[0].context.spanID, span1.context.spanID)
        XCTAssertEqual(exporter.spans[1].context.spanID, span2.context.spanID)
        XCTAssertEqual(exporter.spans[2].context.spanID, span3.context.spanID)
        XCTAssertEqual(exporter.spans[3].context.spanID, span4.context.spanID)
        XCTAssertEqual(exporter.spans[4].context.spanID, span5.context.spanID)
        XCTAssertEqual(exporter.spans[5].context.spanID, span6.context.spanID)
        XCTAssertEqual(exporter.spans[6].context.spanID, span7.context.spanID)

        try processor.shutdownGracefully().wait()
    }

    func test_dropsOldestSpansWhenQueueIsFull() throws {
        let span1 = try recordedSpan()
        let span2 = try recordedSpan()
        let span3 = try recordedSpan()
        let span4 = try recordedSpan()

        let exporter = AwaitingSpanExporter(expectedNumberOfSpans: 3, eventLoopGroup: eventLoopGroup)
        let processor = OTel.BatchSpanProcessor(
            maxBatchSize: 3,
            maxQueueSize: 3,
            interval: .milliseconds(10),
            exportingTo: exporter,
            eventLoopGroup: eventLoopGroup
        )

        for span in [span1, span2, span3, span4] {
            processor.processEndedSpan(span)
        }

        try exporter.shutdownGracefully().wait()

        XCTAssertEqual(exporter.spans.count, 3, "All 3 spans should have been exported.")
        XCTAssertEqual(exporter.numberOfBatches, 1, "All 3 spans should have been exported in one batch.")

        XCTAssertEqual(exporter.spans[0].context.spanID, span2.context.spanID)
        XCTAssertEqual(exporter.spans[1].context.spanID, span3.context.spanID)
        XCTAssertEqual(exporter.spans[2].context.spanID, span4.context.spanID)

        try processor.shutdownGracefully().wait()
    }

    private func recordedSpan() throws -> OTel.RecordedSpan {
        let span = OTel.Tracer.Span.stub(spanContext: .stub(spanID: .random()))
        span.end()
        return try XCTUnwrap(OTel.RecordedSpan(span))
    }
}

private final class AwaitingSpanExporter: OTelSpanExporter {
    private let expectedNumberOfSpans: Int
    private let eventLoopGroup: EventLoopGroup
    private let exportPromise: EventLoopPromise<Void>
    private(set) var spans = [OTel.RecordedSpan]() {
        didSet {
            guard spans.count == expectedNumberOfSpans else { return }
            exportPromise.succeed(())
        }
    }

    private(set) var numberOfBatches = 0

    init(expectedNumberOfSpans: Int, eventLoopGroup: EventLoopGroup) {
        self.expectedNumberOfSpans = expectedNumberOfSpans
        self.eventLoopGroup = eventLoopGroup
        exportPromise = eventLoopGroup.next().makePromise()
    }

    func export<C: Collection>(_ batch: C) -> EventLoopFuture<Void> where C.Element == OTel.RecordedSpan {
        numberOfBatches += 1
        spans.append(contentsOf: batch)
        return eventLoopGroup.next().makeSucceededVoidFuture()
    }

    func shutdownGracefully() -> EventLoopFuture<Void> {
        exportPromise.futureResult
    }
}
