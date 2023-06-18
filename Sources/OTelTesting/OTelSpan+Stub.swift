//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@testable import OpenTelemetry
import ServiceContextModule
import Tracing

extension OTelSpan {
    /// A no-op span stub.
    ///
    /// - Parameter context: Defaults to `ServiceContext.topLevel`.
    ///
    /// - Returns: A no-op span stub.
    public static func noOpStub(context: ServiceContext = .topLevel) -> OTelSpan {
        .noOp(.init(context: context))
    }

    /// A recording span stub.
    ///
    /// - Parameters:
    ///   - operationName: Defaults to "test".
    ///   - kind: Defaults to `SpanKind.internal`.
    ///   - context: Defaults to `ServiceContext.topLevel`.
    ///   - spanContext: Defaults to ``OpenTelemetry/OTelSpanContext/stub(traceID:spanID:parentSpanID:traceFlags:traceState:isRemote:)``
    ///   - attributes: Defaults to no attributes.
    ///   - startTimeNanosecondsSinceEpoch: Defaults to `0`.
    ///   - onEnd: Defaults to a no-op closure.
    ///
    /// - Returns: A recording span stub.
    public static func recordingStub(
        operationName: String = "test",
        kind: SpanKind = .internal,
        context: ServiceContext = .topLevel,
        spanContext: OTelSpanContext = .stub(),
        attributes: SpanAttributes = [:],
        startTimeNanosecondsSinceEpoch: UInt64 = 0,
        onEnd: @escaping (OTelFinishedSpan) -> Void = { _ in }
    ) -> OTelSpan {
        .recording(
            operationName: operationName,
            kind: kind,
            context: context,
            spanContext: spanContext,
            attributes: attributes,
            startTimeNanosecondsSinceEpoch: startTimeNanosecondsSinceEpoch,
            onEnd: onEnd
        )
    }
}
