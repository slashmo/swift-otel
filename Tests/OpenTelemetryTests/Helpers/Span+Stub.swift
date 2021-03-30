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

import struct Dispatch.DispatchWallTime
@testable import OpenTelemetry
import Tracing

extension OTel.Tracer.Span {
    static func stub(
        operationName: String = #function,
        spanContext: OTel.SpanContext? = .stub(),
        kind: SpanKind = .internal,
        startTime: DispatchWallTime = .now(),
        attributes: SpanAttributes = [:],
        logger: Logger = Logger(label: #function),
        onEnd: @escaping (OTel.RecordedSpan) -> Void = { _ in }
    ) -> OTel.Tracer.Span {
        var baggage = Baggage.topLevel
        baggage.spanContext = spanContext

        return OTel.Tracer.Span(
            operationName: operationName,
            baggage: baggage,
            kind: kind,
            startTime: startTime,
            attributes: attributes,
            logger: logger,
            onEnd: onEnd
        )
    }
}
