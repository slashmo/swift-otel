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

public extension OTel {
    struct SpanContext: Equatable {
        public let traceID: TraceID
        public internal(set) var spanID: SpanID
        public let parentSpanID: SpanID?
        public internal(set) var traceFlags: TraceFlags
        public internal(set) var traceState: TraceState
    }
}
