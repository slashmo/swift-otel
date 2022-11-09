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

public protocol OTelMetricsProcessor {
    func processMetric(_ log: OTel.RecordedMetric)
    
    /// Shutdown the processor by trying to finish currently processed metrics, but not allowing new ones to be processed.
    func shutdownGracefully() -> EventLoopFuture<Void>
}
