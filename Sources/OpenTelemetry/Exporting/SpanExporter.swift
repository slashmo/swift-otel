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

import NIO

/// An exporter receives processed, sampled spans to export them, e.g. over the network.
public protocol OTelSpanExporter {
    /// Export the given batch of spans asynchronously.
    ///
    /// - Parameters:
    ///   - batch: The batch of spans to export.
    ///   - resource: The resource these spans were running on.
    /// - Returns: An `EventLoopFuture` indicating whether the export succeeded.
    func export(_ batch: ArraySlice<OTel.RecordedSpan>, on resource: OTel.Resource) -> EventLoopFuture<Void>
}

public extension OTel {
    typealias SpanExporter = OTelSpanExporter
}
