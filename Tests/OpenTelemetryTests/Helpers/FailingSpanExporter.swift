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
import OpenTelemetry

struct FailingSpanExporter: OTelSpanExporter {
    private let eventLoopGroup: EventLoopGroup
    private let error: Error

    init(eventLoopGroup: EventLoopGroup, error: Error) {
        self.eventLoopGroup = eventLoopGroup
        self.error = error
    }

    func export(_ batch: ArraySlice<OTel.RecordedSpan>) -> EventLoopFuture<Void> {
        eventLoopGroup.next().makeFailedFuture(error)
    }

    func shutdownGracefully() -> EventLoopFuture<Void> {
        eventLoopGroup.next().makeSucceededVoidFuture()
    }
}
