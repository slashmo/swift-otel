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
    /// A no-op span processor that simply ignores the given spans.
    public struct NoOpSpanProcessor: OTelSpanProcessor {
        private let eventLoopGroup: EventLoopGroup

        /// Initialize a new no-op processor.
        ///
        /// - Parameter eventLoopGroup: The event loop group on which to shut down.
        public init(eventLoopGroup: EventLoopGroup) {
            self.eventLoopGroup = eventLoopGroup
        }

        public func processEndedSpan(_ span: OTel.RecordedSpan) {}

        public func shutdownGracefully() -> EventLoopFuture<Void> {
            eventLoopGroup.next().makeSucceededVoidFuture()
        }
    }
}
