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

import NIO

/// An exporter receives processed logs to export them, e.g. over the network.
public protocol OTelLogExporter {
    /// Export the given batch of logs asynchronously.
    ///
    /// - Parameters:
    ///   - batch: The batch of logs to export.
    /// - Returns: An `EventLoopFuture` indicating whether the export succeeded.
    func exportLogs<C: Collection>(_ batch: C) -> EventLoopFuture<Void> where C.Element == OTel.RecordedLog
    
    /// Shutdown the exporter by trying to finish current exports, but not allowing new ones to be exported.
    func shutdownGracefully() -> EventLoopFuture<Void>
}
