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

import enum Tracing.SpanKind

extension Opentelemetry_Proto_Trace_V1_Span.SpanKind {
    init(_ spanKind: SpanKind) {
        switch spanKind {
        case .server:
            self = .server
        case .client:
            self = .client
        case .producer:
            self = .producer
        case .consumer:
            self = .consumer
        case .internal:
            self = .internal
        }
    }
}
