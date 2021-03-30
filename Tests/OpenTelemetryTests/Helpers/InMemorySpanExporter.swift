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

final class InMemorySpanExporter: OTel.SpanExporter {
    private let eventLoopGroup: EventLoopGroup
    private let lock = Lock()
    private var _spans = [OTel.RecordedSpan]()

    var spans: [OTel.RecordedSpan] {
        lock.withLock { _spans }
    }

    init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }

    func export(_ batch: ArraySlice<OTel.RecordedSpan>, on resource: OTel.Resource) -> EventLoopFuture<Void> {
        lock.withLockVoid {
            _spans.append(contentsOf: batch)
        }
        return eventLoopGroup.next().makeSucceededVoidFuture()
    }
}
