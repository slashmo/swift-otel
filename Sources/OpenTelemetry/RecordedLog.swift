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
import Tracing
import Logging

extension OTel {
    /// Holds the read-only data collected during the lifetime of a span, typically created right after a span was ended.
    public struct RecordedLog {
        public let resource: OTel.Resource
        public let unixTimeNanoseconds: UInt64
        public let level: Logger.Level
        public let message: Logger.Message
        public let metadata: Logger.Metadata?
        public let source: String
        public let file: String
        public let function: String
        public let line: UInt
    }
}
