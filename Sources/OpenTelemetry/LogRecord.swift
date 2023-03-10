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

import struct Dispatch.DispatchWallTime
import Logging

extension OTel {
    public struct LogRecord {
        public let logLevel: Logger.Level
        public let timestamp: DispatchWallTime
        public let message: Logger.Message
        public let metadata: Logger.Metadata?
        public let traceIDBytes: [UInt8]?
        public let spanIDBytes: [UInt8]?

        public init(
            logLevel: Logger.Level,
            timestamp: DispatchWallTime,
            message: Logger.Message,
            metadata: Logger.Metadata?,
            traceIDBytes: [UInt8]?,
            spanIDBytes: [UInt8]?
        ) {
            self.logLevel = logLevel
            self.timestamp = timestamp
            self.message = message
            self.metadata = metadata
            self.traceIDBytes = traceIDBytes
            self.spanIDBytes = spanIDBytes
        }
    }
}
