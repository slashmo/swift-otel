//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import InstrumentationBaggage
import Logging

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Logger.MetadataProvider {
    /// A metadata provider exposing the current trace and span ID.
    ///
    /// - Parameters:
    ///   - traceIDKey: The metadata key of the trace ID. Defaults to "trace_id".
    ///   - spanIDKey: The metadata key of the span ID. Defaults to "span_id".
    /// - Returns: A metadata provider ready to use with Logging.
    public static func otel(traceIDKey: String = "trace_id", spanIDKey: String = "span_id") -> Logger.MetadataProvider {
        .init {
            guard let spanContext = Baggage.current?.spanContext else { return [:] }
            return [
                traceIDKey: .stringConvertible(spanContext.traceID),
                spanIDKey: .stringConvertible(spanContext.spanID),
            ]
        }
    }

    /// A metadata provider exposing the current trace and span ID.
    public static let otel = Logger.MetadataProvider.otel()
}
