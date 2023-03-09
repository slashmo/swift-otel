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
import NIOConcurrencyHelpers
import OpenTelemetry

final class InMemorySpanExporter: OTelSpanExporter {
    private let eventLoopGroup: EventLoopGroup
    private let lock = NIOLock()
    private var _spans = [OTel.RecordedSpan]()
    private(set) var numberOfExports = 0

    var spans: [OTel.RecordedSpan] {
        lock.withLock { _spans }
    }

    init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }

    func export<C: Collection>(_ batch: C) -> EventLoopFuture<Void> where C.Element == OTel.RecordedSpan {
        numberOfExports += 1
        lock.withLockVoid {
            _spans.append(contentsOf: batch)
        }
        return eventLoopGroup.next().makeSucceededVoidFuture()
    }

    func shutdownGracefully() -> EventLoopFuture<Void> {
        eventLoopGroup.next().makeSucceededVoidFuture()
    }
}
