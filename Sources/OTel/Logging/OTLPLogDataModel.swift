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

@_spi(Logging)
public struct OTelLog: Equatable, Sendable {
    public let body: String
    public let level: Logger.Level
    public let metadata: Logger.Metadata?
    public let timeNanosecondsSinceEpoch: UInt64
}
