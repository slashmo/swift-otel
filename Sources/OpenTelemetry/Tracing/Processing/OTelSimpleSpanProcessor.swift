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

/// A span processor that simply forwards finished spans to a configured exporter, one at a time as soon as their ended.
///
/// - Warning: It is not recommended to use ``OTelSimpleSpanProcessor`` in production
/// since it will lead to an unnecessary amount of network calls within the exporter. Instead it is recommended
/// to use a batching span processor such as ``OTelBatchSpanProcessor`` that will forward multiple spans
/// to the exporter at once.
public struct OTelSimpleSpanProcessor<Exporter: OTelSpanExporter>: OTelSpanProcessor {
    private let exporter: Exporter

    /// Create a span processor immediately forwarding spans to the given exporter.
    ///
    /// - Parameter exporter: The exporter to receive finished spans.
    /// On processor shutdown this exporter will also automatically be shut down.
    public init(exportingTo exporter: Exporter) {
        self.exporter = exporter
    }

    public func onStart(_ span: OTelSpan, parentContext: ServiceContext) async {
        // no-op
    }

    public func onEnd(_ span: OTelFinishedSpan) async {
        guard span.spanContext.traceFlags.contains(.sampled) else { return }

        do {
            try await exporter.export([span])
        } catch {
            // simple span processor does not attempt retries, so this is no-op
        }
    }

    public func shutdown() async throws {
        await exporter.shutdown()
    }

    public func forceFlush() async throws {
        // no-op
    }
}
