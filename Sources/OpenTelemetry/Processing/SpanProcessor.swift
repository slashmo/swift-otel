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

/// A processor receives ended spans from the tracer and potentially hands them over to an exporter.
public protocol OTelSpanProcessor {
    /// Process the given span.
    ///
    /// - Parameters:
    ///   - span: The span to be processed.
    func processEndedSpan(_ span: OTel.RecordedSpan)

    /// Shutdown the processor by trying to finish currently processed spans, but not allowing new ones to be processed.
    func shutdownGracefully() -> EventLoopFuture<Void>
}
