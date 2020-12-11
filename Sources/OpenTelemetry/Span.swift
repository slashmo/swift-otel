//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2020 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Dispatch.DispatchWallTime
import Tracing

public final class OpenTelemetrySpan: Span {
    public let name: String
    public let kind: SpanKind
    public let startTime: DispatchWallTime
    public private(set) var endTime: DispatchWallTime?
    public let baggage: Baggage
    public var attributes: SpanAttributes = [:]
    public private(set) var isRecording = false
    public private(set) var status: SpanStatus = .init(canonicalCode: .unknown)
    public private(set) var events = [SpanEvent]()
    public private(set) var links = [SpanLink]()

    private let onEnd: (OpenTelemetrySpan) -> Void

    public init(name: String, kind: SpanKind, startTime: DispatchWallTime, baggage: Baggage, onEnd: @escaping (OpenTelemetrySpan) -> Void) {
        self.name = name
        self.kind = kind
        self.startTime = startTime
        self.baggage = baggage
        self.onEnd = onEnd
    }

    public func setStatus(_ status: SpanStatus) {
        self.status = status
    }

    public func addEvent(_ event: SpanEvent) {
        self.events.append(event)
    }

    public func recordError(_ error: Error) {
        addEvent(SpanEvent(name: "exception", attributes: [
            "exception.type": .string(String(describing: type(of: error))),
            "exception.message": .string(String(describing: error)),
        ]))
    }

    public func addLink(_ link: SpanLink) {
        self.links.append(link)
    }

    public func end(at time: DispatchWallTime) {
        self.endTime = time
        self.onEnd(self)
    }
}
