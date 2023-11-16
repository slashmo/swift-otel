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

import Tracing

/// A read-only representation of an ended ``OTelSpan``.
public struct OTelFinishedSpan: Sendable {
    /// The context of this span.
    public let spanContext: OTelSpanContext

    /// The spans operation name.
    public let operationName: String

    /// The spans kind.
    public let kind: SpanKind

    /// The spans status.
    public let status: SpanStatus?

    /// The time when the span started in nanoseconds since epoch.
    public let startTimeNanosecondsSinceEpoch: UInt64

    /// The time when the span ended in nanoseconds since epoch.
    public let endTimeNanosecondsSinceEpoch: UInt64

    /// The attributes added to the span.
    public let attributes: SpanAttributes

    /// The events added to the span.
    public let events: [SpanEvent]

    /// The links from this span to other spans.
    public let links: [SpanLink]
}
