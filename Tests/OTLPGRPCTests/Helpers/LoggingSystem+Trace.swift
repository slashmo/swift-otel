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

@testable import Logging

extension LoggingSystem {
    static func bootstrapInternal(logLevel: Logger.Level) {
        LoggingSystem.bootstrapInternal { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel
            return handler
        }
    }
}
