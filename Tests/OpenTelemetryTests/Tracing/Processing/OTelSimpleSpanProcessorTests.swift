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

import OpenTelemetry
import OTelTesting
import XCTest

final class OTelSimpleSpanProcessorTests: XCTestCase {
    func test_onEnd_withSampledSpan_forwardsSampledSpanToExporter() async throws {
        let exporter = OTelInMemorySpanExporter()
        let processor = OTelSimpleSpanProcessor(exportingTo: exporter)

        let span = OTelFinishedSpan.stub(traceFlags: .sampled, operationName: "test")
        processor.onEnd(span)

        // wait for exporter to be invoked asynchronously
        try await Task.sleep(for: .milliseconds(100))

        let exportedBatches = await exporter.exportedBatches
        XCTAssertEqual(exportedBatches.count, 1)

        let batch = try XCTUnwrap(exportedBatches.first)
        XCTAssertEqual(batch.map(\.operationName), ["test"])
    }

    func test_onEnd_withNonSampledSpan_doesNotForwardSpanToExporter() async throws {
        let exporter = OTelInMemorySpanExporter()
        let processor = OTelSimpleSpanProcessor(exportingTo: exporter)

        let span = OTelFinishedSpan.stub(traceFlags: [], operationName: "test")
        processor.onEnd(span)

        // wait for exporter to be invoked asynchronously
        try await Task.sleep(for: .milliseconds(100))

        let exportedBatches = await exporter.exportedBatches
        XCTAssertTrue(exportedBatches.isEmpty)
    }

    func test_forceFlush_forceFlushesExporter() async throws {
        let exporter = OTelInMemorySpanExporter()
        let processor = OTelSimpleSpanProcessor(exportingTo: exporter)

        try await processor.forceFlush()

        let numberOfForceFlushes = await exporter.numberOfForceFlushes
        XCTAssertEqual(numberOfForceFlushes, 1)
    }

    func test_shutdown_shutsDownExporter() async throws {
        let exporter = OTelInMemorySpanExporter()
        let processor = OTelSimpleSpanProcessor(exportingTo: exporter)

        try await processor.shutdown()

        let numberOfShutdowns = await exporter.numberOfShutdowns
        XCTAssertEqual(numberOfShutdowns, 1)
    }
}
