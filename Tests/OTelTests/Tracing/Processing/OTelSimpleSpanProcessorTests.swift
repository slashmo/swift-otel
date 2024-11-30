//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import OTel
import OTelTesting
import XCTest

final class OTelSimpleSpanProcessorTests: XCTestCase {
    func test_onEnd_withSampledSpan_forwardsSampledSpanToExporter() async throws {
        let exporter = OTelStreamingSpanExporter()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        Task {
            try await processor.run()
        }

        let span = OTelFinishedSpan.stub(traceFlags: .sampled, operationName: "test")
        processor.onEnd(span)

        // wait for batch to be exported
        var exportedBatchess = await exporter.batches.makeAsyncIterator()
        let batch = await exportedBatchess.next()

        XCTAssertEqual(try XCTUnwrap(batch).map(\.operationName), ["test"])
    }

    func test_onEnd_withNonSampledSpan_doesNotForwardSpanToExporter() async throws {
        let exporter = OTelInMemorySpanExporter()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        let span = OTelFinishedSpan.stub(traceFlags: [], operationName: "test")
        processor.onEnd(span)

        // wait for exporter to be invoked asynchronously
        try await Task.sleep(for: .milliseconds(100))

        let exportedBatches = await exporter.exportedBatches
        XCTAssertTrue(exportedBatches.isEmpty)
    }

    func test_forceFlush_forceFlushesExporter() async throws {
        let exporter = OTelInMemorySpanExporter()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        try await processor.forceFlush()

        let numberOfForceFlushes = await exporter.numberOfForceFlushes
        XCTAssertEqual(numberOfForceFlushes, 1)
    }

    func test_shutdown_shutsDownExporter() async throws {
        let exporter = OTelInMemorySpanExporter()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        try await processor.shutdown()

        let numberOfShutdowns = await exporter.numberOfShutdowns
        XCTAssertEqual(numberOfShutdowns, 1)
    }
}
