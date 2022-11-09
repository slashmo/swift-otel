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
import NIOConcurrencyHelpers

extension OTel {
    /// A processor which hands off ended spans to a given exporter in batches.
    ///
    /// - SeeAlso: [OTel Spec: Batching processor](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/sdk.md#batching-processor)
    public final class BatchSpanProcessor: OTelSpanProcessor {
        private let exporter: OTelSpanExporter
        private let eventLoopGroup: EventLoopGroup
        private let maxQueueSize: Int
        private let maxBatchSize: Int

        private var queue = CircularBuffer<OTel.RecordedSpan>()
        private let queueLock = NIOLock()
        private var exportTask: RepeatedTask!

        /// Initialize a batch span processor.
        /// - Parameters:
        ///   - maxBatchSize: The maximum number of spans exported in one batch. Defaults to `512`.
        ///   - maxQueueSize: The maximum number of spans queued for export. Defaults to `2048`.
        ///   Old spans will be dropped if the number of queued spans exceeds this max size.
        ///   - interval: The time interval in which to export batches. Defaults to 5 seconds.
        ///   - exporter: The exporter which receives processed span batches.
        ///   - eventLoopGroup: The event loop group on which to process.
        public init(
            maxBatchSize: Int = 512,
            maxQueueSize: Int = 2048,
            interval: TimeAmount = .seconds(5),
            exportingTo exporter: OTelSpanExporter,
            eventLoopGroup: EventLoopGroup
        ) {
            self.exporter = exporter
            self.eventLoopGroup = eventLoopGroup
            self.maxBatchSize = maxBatchSize
            self.maxQueueSize = maxQueueSize
            exportTask = eventLoopGroup.next().scheduleRepeatedAsyncTask(
                initialDelay: interval,
                delay: interval,
                exportBatch
            )
        }

        public func processEndedSpan(_ span: OTel.RecordedSpan) {
            queueLock.withLock {
                if queue.count == maxQueueSize {
                    queue.removeFirst()
                }
                queue.append(span)
            }
        }

        public func shutdownGracefully() -> EventLoopFuture<Void> {
            let promise = eventLoopGroup.next().makePromise(of: Void.self)
            exportTask.cancel(promise: promise)
            return promise.futureResult
        }

        private func exportBatch(_ task: RepeatedTask) -> EventLoopFuture<Void> {
            queueLock.withLock {
                guard !queue.isEmpty else {
                    return eventLoopGroup.next().makeSucceededVoidFuture()
                }
                let spans = queue.prefix(maxBatchSize)
                queue.removeFirst(spans.count)
                return exporter.exportSpans(spans)
            }
        }
    }
}
