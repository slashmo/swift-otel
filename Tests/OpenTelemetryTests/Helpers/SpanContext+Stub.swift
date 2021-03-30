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

@testable import OpenTelemetry

extension OTel.SpanContext {
    static func stub(
        traceID: OTel.TraceID = .stub,
        spanID: OTel.SpanID = .stub,
        parentSpanID: OTel.SpanID? = nil,
        traceFlags: OTel.TraceFlags = [],
        traceState: OTel.TraceState? = nil,
        isRemote: Bool = false
    ) -> Self {
        OTel.SpanContext(
            traceID: traceID,
            spanID: spanID,
            parentSpanID: parentSpanID,
            traceFlags: traceFlags,
            traceState: traceState,
            isRemote: isRemote
        )
    }
}
