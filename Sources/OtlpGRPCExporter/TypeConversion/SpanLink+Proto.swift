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

import struct Foundation.Data
import Tracing

extension Opentelemetry_Proto_Trace_V1_Span.Link {
    init?(_ spanLink: SpanLink) {
        guard let spanContext = spanLink.baggage.spanContext else { return nil }
        self.traceID = Data(spanContext.traceID.bytes)
        self.spanID = Data(spanContext.spanID.bytes)
        if let traceState = spanContext.traceState {
            self.traceState = traceState.description
        }
        self.attributes = .init(spanLink.attributes)
    }
}
