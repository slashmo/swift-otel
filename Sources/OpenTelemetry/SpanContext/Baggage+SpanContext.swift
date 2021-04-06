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

import CoreBaggage

extension Baggage {
    public internal(set) var spanContext: OTel.SpanContext? {
        get {
            self[SpanContextKey]
        }
        set {
            self[SpanContextKey] = newValue
        }
    }
}

extension OTel.SpanContext: CustomStringConvertible {
    public var description: String {
        let flagString = traceFlags.rawValue < 10 ? "0\(traceFlags.rawValue)" : "\(traceFlags.rawValue)"
        return "\(traceID)-\(spanID)-\(flagString)"
    }
}

private enum SpanContextKey: BaggageKey {
    typealias Value = OTel.SpanContext

    static var nameOverride: String? = "otel-span-context"
}
