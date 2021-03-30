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

/// A processor receives ended spans from the tracer and potentially hands them over to an exporter.
public protocol OTelSpanProcessor {
    /// Process the given span.
    ///
    /// - Parameters:
    ///   - span: The span to be processed.
    ///   - resource: The resource the span was running on.
    func processEndedSpan(_ span: OTel.RecordedSpan, on resource: OTel.Resource)
}

public extension OTel {
    typealias SpanProcessor = OTelSpanProcessor
}
