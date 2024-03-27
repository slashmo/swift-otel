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

import AsyncAlgorithms
import Logging
import NIOConcurrencyHelpers
import ServiceLifecycle
import Tracing

@_spi(Logging)
public struct OTelLogHandler: Sendable, LogHandler {
    public var metadata: Logger.Metadata
    public var logLevel: Logger.Level
    private let processor: any OTelLogRecordProcessor
    private let nanosecondsSinceEpoch: @Sendable () -> UInt64

    public init(
        processor: any OTelLogRecordProcessor,
        logLevel: Logger.Level,
        metadata: Logger.Metadata = [:]
    ) {
        self.init(
            processor: processor,
            logLevel: logLevel,
            metadata: metadata,
            nanosecondsSinceEpoch: { DefaultTracerClock.now.nanosecondsSinceEpoch }
        )
    }

    package init(
        processor: any OTelLogRecordProcessor,
        logLevel: Logger.Level,
        metadata: Logger.Metadata,
        nanosecondsSinceEpoch: @escaping @Sendable () -> UInt64
    ) {
        self.processor = processor
        self.logLevel = logLevel
        self.metadata = metadata
        self.nanosecondsSinceEpoch = nanosecondsSinceEpoch
    }

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let effectiveMetadata: Logger.Metadata?
        if let metadata {
            effectiveMetadata = self.metadata.merging(metadata, uniquingKeysWith: { $1 })
        } else {
            effectiveMetadata = self.metadata.isEmpty ? nil : self.metadata
        }

        let record = OTelLogRecord(
            body: message.description,
            level: level,
            metadata: effectiveMetadata,
            timeNanosecondsSinceEpoch: nanosecondsSinceEpoch()
        )

        processor.onEmit(record)
    }
}
