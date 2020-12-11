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

import Baggage
import W3CTraceContext

extension Baggage {
    private enum TraceContextKey: Baggage.Key {
        typealias Value = TraceContext
    }

    public var traceContext: TraceContext? {
        get {
            self[TraceContextKey]
        }
        set {
            self[TraceContextKey] = newValue
        }
    }
}
