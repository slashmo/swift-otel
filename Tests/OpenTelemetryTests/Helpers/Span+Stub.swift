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

import Logging
@testable import OpenTelemetry
import Tracing

extension OTel.Tracer.Span {
    static func stub(
        operationName: String = #function,
        spanContext: OTel.SpanContext? = .stub(),
        kind: SpanKind = .internal,
        startTime: UInt64 = 0,
        attributes: SpanAttributes = [:],
        resource: OTel.Resource = OTel.Resource(),
        logger: Logger = Logger(label: #function),
        onEnd: @escaping (OTel.RecordedSpan) -> Void = { _ in }
    ) -> OTel.Tracer.Span {
        var context = ServiceContext.topLevel
        context.spanContext = spanContext

        return OTel.Tracer.Span(
            operationName: operationName,
            context: context,
            kind: kind,
            startTime: startTime,
            attributes: attributes,
            resource: resource,
            logger: logger,
            onEnd: onEnd
        )
    }
}
