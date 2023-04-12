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

import Tracing

extension Opentelemetry_Proto_Trace_V1_Span.Event {
    init(_ spanEvent: SpanEvent) {
        name = spanEvent.name
        #warning("TODO: Use spanEvent.nanosecondsSinceEpoch")
        timeUnixNano = spanEvent.millisecondsSinceEpoch * 1_000_000
        attributes = .init(spanEvent.attributes)
    }
}
