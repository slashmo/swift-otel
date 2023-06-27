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

/// The configuration options for an ``OTelBatchSpanProcessor``.
public struct OTelBatchSpanProcessorConfiguration {
    /// The maximum queue size.
    ///
    /// - Warning: After this size is reached spans will be dropped.
    public var maximumQueueSize: UInt

    /// The maximum delay between two consecutive span exports.
    public var scheduleDelayInMilliseconds: UInt

    /// The maximum batch size of each export.
    ///
    /// - Note: If the queue reaches this size, a batch will be exported even if ``scheduleDelayInMilliseconds`` have not elapsed.
    public var maximumExportBatchSize: UInt

    /// The number of milliseconds a single export can run until it is cancelled.
    public var exportTimeoutInMilliseconds: UInt

    /// Create a batch span processor configuration.
    ///
    /// - Parameters:
    ///   - environment: The environment variables.
    ///   - maximumQueueSize: A maximum queue size used even if `OTEL_BSP_MAX_QUEUE_SIZE` is set. Defaults to `2048` if both are `nil`.
    ///   - scheduleDelayInMilliseconds: A schedule delay used even if `OTEL_BSP_SCHEDULE_DELAY` is set. Defaults to `5000` if both are `nil`.
    ///   - maximumExportBatchSize: - maximumExportBatchSize: A maximum export batch size used even if `OTEL_BSP_MAX_EXPORT_BATCH_SIZE` is set. Defaults `512` if both are `nil`.
    ///   - exportTimeoutInMilliseconds: An export timeout used even if `OTEL_BSP_EXPORT_TIMEOUT` is set. Defaults to `30000` if both are `nil`.
    public init(
        environment: OTelEnvironment,
        maximumQueueSize: UInt? = nil,
        scheduleDelayInMilliseconds: UInt? = nil,
        maximumExportBatchSize: UInt? = nil,
        exportTimeoutInMilliseconds: UInt? = nil
    ) {
        self.maximumQueueSize = environment.requiredValue(
            programmaticOverride: maximumQueueSize,
            key: "OTEL_BSP_MAX_QUEUE_SIZE",
            defaultValue: 2048,
            transformValue: UInt.init
        )

        self.scheduleDelayInMilliseconds = environment.requiredValue(
            programmaticOverride: scheduleDelayInMilliseconds,
            key: "OTEL_BSP_SCHEDULE_DELAY",
            defaultValue: 5000,
            transformValue: UInt.init
        )

        self.maximumExportBatchSize = environment.requiredValue(
            programmaticOverride: maximumExportBatchSize,
            key: "OTEL_BSP_MAX_EXPORT_BATCH_SIZE",
            defaultValue: 512,
            transformValue: UInt.init
        )

        self.exportTimeoutInMilliseconds = environment.requiredValue(
            programmaticOverride: exportTimeoutInMilliseconds,
            key: "OTEL_BSP_EXPORT_TIMEOUT",
            defaultValue: 30000,
            transformValue: UInt.init
        )
    }
}
