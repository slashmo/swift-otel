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

extension OTel {
    /// A no-op span exporter that simply ignores the given spans and always succeeds.
    public struct NoOpMetricsExporter: OTelMetricsExporter {
        private let eventLoopGroup: EventLoopGroup
        
        /// Initialize a new no-op span exporter.
        ///
        /// - Parameter eventLoopGroup: The event loop group used to return the succeeding future.
        public init(eventLoopGroup: EventLoopGroup) {
            self.eventLoopGroup = eventLoopGroup
        }
        
        public func exportMetrics<C>(_ batch: C) -> EventLoopFuture<Void> where C : Collection, C.Element == OTel.RecordedMetric {
            eventLoopGroup.next().makeSucceededVoidFuture()
        }
        
        public func shutdownGracefully() -> EventLoopFuture<Void> {
            eventLoopGroup.next().makeSucceededVoidFuture()
        }
    }
}
