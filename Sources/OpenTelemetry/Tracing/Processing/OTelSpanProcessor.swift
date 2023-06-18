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

import ServiceContextModule

/// Span processor allow for processing spans throught their lifetime via ``onStart(_:parentContext:)`` and ``onEnd(_:)`` calls.
/// Usually, span processors will forward ended spans to a configurable ``OTelSpanExporter``.
///
/// [OpenTelemetry specification: Span processor](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/trace/sdk.md#span-processor)
///
/// ### Implementation Notes
///
/// On shutdown, processors forwarding spans to an ``OTelSpanExporter`` MUST shutdown that exporter.
public protocol OTelSpanProcessor {
    /// Called whenever a new recording span was started.
    ///
    /// - Parameters:
    ///   - span: The mutable span that was started.
    ///   - parentContext: The span's parent service context.
    func onStart(_ span: OTelSpan, parentContext: ServiceContext)

    /// Called whenever a recording span was ended.
    ///
    /// - Parameter span: The read-only finished span.
    func onEnd(_ span: OTelFinishedSpan)

    /// Force span processors that batch spans to flush immediately.
    func forceFlush() async throws

    /// Asynchronously shut down the span processor.
    func shutdown() async throws
}