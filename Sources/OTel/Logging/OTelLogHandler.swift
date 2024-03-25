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
import Logging
import Tracing

@_spi(Logging)
public struct OTelLogHandler: Sendable, LogHandler {
    public var metadata: Logging.Logger.Metadata
    public var logLevel: Logging.Logger.Level
    private let processor: any OTelLogProcessor

    public init(
        processor: any OTelLogProcessor,
        logLevel: Logger.Level,
        metadata: Logger.Metadata = [:]
    ) {
        self.processor = processor
        self.logLevel = logLevel
        self.metadata = metadata
    }

    public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
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
        let instant = DefaultTracerClock().now

        let message = OTelLog(
            body: message.description,
            level: level,
            metadata: metadata,
            timeNanosecondsSinceEpoch: instant.nanosecondsSinceEpoch
        )

        processor.onLog(message)
    }
}
