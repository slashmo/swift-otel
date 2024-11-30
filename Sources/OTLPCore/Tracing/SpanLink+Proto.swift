//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 the Swift OTel project authors
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
    /// Create a span link from a `SpanLink`.
    ///
    /// - Parameter link: The `SpanLink` to cast.
    /// - Returns: `nil` if the `SpanLink`s context does not contain a span context.
    public init?(_ link: SpanLink) {
        guard let spanContext = link.context.spanContext else { return nil }
        self.traceID = Data(spanContext.traceID.bytes)
        self.spanID = Data(spanContext.spanID.bytes)
        if let traceStateHeaderValue = spanContext.traceStateHeaderValue {
            self.traceState = traceStateHeaderValue
        }
        self.attributes = .init(link.attributes)
    }
}
