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

import OTel
import Tracing
import W3CTraceContext

public struct OTelInlineSampler: OTelSampler {
    private let onSamplingResult: @Sendable (
        _ operationName: String,
        _ kind: SpanKind,
        _ traceID: TraceID,
        _ attributes: SpanAttributes,
        _ links: [SpanLink],
        _ parentContext: ServiceContext
    ) -> OTelSamplingResult

    public init(
        onSamplingResult: @escaping @Sendable (
            _ operationName: String,
            _ spanKind: SpanKind,
            _ traceID: TraceID,
            _ attributes: SpanAttributes,
            _ links: [SpanLink],
            _ parentContext: ServiceContext
        ) -> OTelSamplingResult
    ) {
        self.onSamplingResult = onSamplingResult
    }

    public func samplingResult(
        operationName: String,
        kind: SpanKind,
        traceID: TraceID,
        attributes: SpanAttributes,
        links: [SpanLink],
        parentContext: ServiceContext
    ) -> OTelSamplingResult {
        onSamplingResult(operationName, kind, traceID, attributes, links, parentContext)
    }
}
