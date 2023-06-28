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

import DequeModule
import Logging

/// A span processor that batches finished spans and forwards them to a configured exporter.
///
/// [OpenTelemetry Specification: Batching processor](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/trace/sdk.md#batching-processor)
public actor OTelBatchSpanProcessor<Exporter: OTelSpanExporter>: OTelSpanProcessor {
    private let configuration: OTelBatchSpanProcessorConfiguration
    private let exporter: Exporter
    private let logger = Logger(label: "OTelBatchSpanProcessor")
    private var exportLoop: Task<Void, Never>?

    internal /* for testing */ private(set) var queue = Deque<OTelFinishedSpan>()

    /// Create a batch span processor.
    ///
    /// - Parameters:
    ///   - configuration: The configuration applied to this batch span processor instance.
    ///   - exporter: The exporter to forward batches of ended spans to.
    public init(configuration: OTelBatchSpanProcessorConfiguration, exportingTo exporter: Exporter) {
        precondition(
            configuration.maximumExportBatchSize <= configuration.maximumQueueSize,
            """
            The maximum export batch size (\(configuration.maximumExportBatchSize)) must be smaller than or equal to \
            the maximum queue size (\(configuration.maximumQueueSize)).
            """
        )

        self.configuration = configuration
        self.exporter = exporter

        Task {
            await startExportLoop()
        }
    }

    public func onEnd(_ span: OTelFinishedSpan) async {
        let queueSizeAfterInsertion = queue.count + 1

        if queueSizeAfterInsertion < configuration.maximumQueueSize {
            queue.append(span)
        } else if queueSizeAfterInsertion == configuration.maximumQueueSize {
            logger.trace("Exporting batch ahead of schedule because enough spans were accumulated.")
            queue.append(span)
            await exportBatch()
            exportLoop?.cancel()
            exportLoop = nil
            startExportLoop()
        } else {
            logger.warning("Dropping span because the maximum queue size was reached.", metadata: [
                "trace_id": "\(span.spanContext.traceID)",
                "span_id": "\(span.spanContext.spanID)",
                "operation_name": "\(span.operationName)",
            ])
        }
    }

    public func forceFlush() async throws {
        let chunkSize = Int(configuration.maximumExportBatchSize)
        let batches = stride(from: 0, to: queue.count, by: chunkSize).map {
            queue[$0 ..< min($0 + Int(configuration.maximumExportBatchSize), queue.count)]
        }
        logger.debug("Force flushing spans.")

        queue.removeAll()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for batch in batches {
                group.addTask { try await self.export(batch) }
            }

            try await group.waitForAll()
        }
    }

    public func shutdown() async throws {
        try await forceFlush()
        await exporter.shutdown()
    }

    private func exportBatch() async {
        guard !queue.isEmpty else { return }
        let spans = queue.prefix(Int(configuration.maximumExportBatchSize))

        /*
         Spans are removed from the queue even if exporting them fails
         because it's up to the individual span exporting to implement
         retrying.
         */
        queue.removeFirst(spans.count)

        Task {
            try await export(spans)
        }
    }

    private func export(_ spans: some Collection<OTelFinishedSpan>) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await self.exporter.export(spans)
                    self.logger.trace("Exported batch of spans.")
                } catch {
                    self.logger.error("Export failed.", metadata: [
                        "error": "\(String(describing: type(of: error)))",
                        "error_description": "\(error))",
                    ])
                }
            }

            group.addTask {
                try await Task.sleep(for: .milliseconds(self.configuration.exportTimeoutInMilliseconds))
                self.logger.error("Exporter timed out.")
                throw CancellationError()
            }

            guard try await group.next() != nil else {
                throw CancellationError()
            }
            group.cancelAll()
        }
    }

    private func startExportLoop() {
        exportLoop = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(configuration.scheduleDelayInMilliseconds))
                    await exportBatch()
                } catch {
                    break
                }
            }
        }
    }
}
