//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO

public protocol OTelLogRecordExporter {
    func export<C: Collection>(_ batch: C) -> EventLoopFuture<Void> where C.Element == OTel.LogRecord

    func shutdownGracefully() -> EventLoopFuture<Void>
}
