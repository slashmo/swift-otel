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

import Logging
import NIOConcurrencyHelpers

package struct RecordingLogHandler: LogHandler {
    package typealias LogFunctionCall = (level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?)

    package let recordedLogMessages = NIOLockedValueBox([LogFunctionCall]())

    package init() {}

    package func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        recordedLogMessages.withLockedValue { $0.append((level, message, metadata)) }
    }

    package var metadata: Logging.Logger.Metadata {
        get { [:] }
        set(newValue) { fatalError("unimplemented") }
    }

    package var logLevel: Logging.Logger.Level {
        get { .trace }
        set(newValue) { fatalError("unimplemented") }
    }

    package subscript(metadataKey _: String) -> Logging.Logger.Metadata.Value? {
        get { fatalError("unimplemented") }
        set(newValue) { fatalError("unimplemented") }
    }
}
