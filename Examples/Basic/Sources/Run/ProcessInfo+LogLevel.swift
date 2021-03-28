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

import class Foundation.ProcessInfo
import Logging

extension ProcessInfo {
    var logLevel: Logger.Level {
        environment["LOG_LEVEL"].flatMap { Logger.Level(rawValue: $0.lowercased()) } ?? .info
    }
}
