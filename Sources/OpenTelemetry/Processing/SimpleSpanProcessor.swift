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

import Logging
import NIO

extension OTel {
    /// A span processor that simply forwards all *sampled* spans to a given exporter.
    public struct SimpleSpanProcessor: OTelSpanProcessor {
        private let exporter: OTelSpanExporter

        /// Initialize a simple span processor forwarding to the given exporter.
        ///
        /// - Parameter exporter: The exporter to forward sampled spans to.
        public init(exportingTo exporter: OTelSpanExporter) {
            self.exporter = exporter
        }

        public func processEndedSpan(_ span: OTel.RecordedSpan, on resource: OTel.Resource) {
            guard span.context.traceFlags.contains(.sampled) else { return }
            _ = exporter.export([span], on: resource)
        }

        public func shutdownGracefully() -> EventLoopFuture<Void> {
            exporter.shutdownGracefully()
        }
    }
}
