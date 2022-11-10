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
import NIOConcurrencyHelpers

#if os(Linux)
import Glibc
#else
import Darwin
#endif

extension OTel {
    final class LogHandler: Logging.LogHandler {
        public var metadata: Logger.Metadata
        public var logLevel: Logging.Logger.Level
        private let resource: OTel.Resource
        private let processor: OTelLogProcessor
        
        public subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
            get {
                metadata[metadataKey]
            }
            set {
                metadata[metadataKey] = newValue
            }
        }

        init(
            resource: OTel.Resource,
            logLevel: Logger.Level,
            metadata: Logger.Metadata,
            processor: OTelLogProcessor
        ) {
            self.resource = resource
            self.metadata = metadata
            self.logLevel = logLevel
            self.processor = processor
        }
        
        func log(
            level: Logger.Level,
            message: Logger.Message,
            metadata: Logger.Metadata?,
            source: String,
            file: String,
            function: String,
            line: UInt
        ) {
            let unixTime = time(nil)
            
            let log = RecordedLog(
                resource: resource,
                unixTimeNanoseconds: UInt64(unixTime),
                level: level,
                message: message,
                metadata: metadata,
                source: source,
                file: file,
                function: function,
                line: line
            )
            
            self.processor.processLog(log)
        }
    }
}
