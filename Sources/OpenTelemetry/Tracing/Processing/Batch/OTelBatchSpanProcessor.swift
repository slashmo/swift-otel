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

/// A span processor that batches finished spans and forwards them to a configured exporter.
///
/// [OpenTelemetry Specification: Batching processor](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/trace/sdk.md#batching-processor)
public actor OTelBatchSpanProcessor<Exporter: OTelSpanExporter>: OTelSpanProcessor {
    private let configuration: OTelBatchSpanProcessorConfiguration
    private let exporter: Exporter

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
    }

    public func onEnd(_ span: OTelFinishedSpan) async {
        // TODO: Implement batching
    }

    public func forceFlush() async throws {
        // TODO: Implement force flush
    }

    public func shutdown() async throws {
        // TODO: Implement shut down
    }
}
