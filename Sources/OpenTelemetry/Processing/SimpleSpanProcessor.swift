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

public extension OTel {
    /// A span processor that simply forwards all *sampled* spans to a given exporter.
    struct SimpleSpanProcessor: SpanProcessor {
        private let exporter: SpanExporter
        private let logger: Logger

        /// Initialize a simple span processor forwarding to the given exporter.
        ///
        /// - Parameters:
        ///   - exporter: The exporter to forward sampled spans to.
        ///   - logger: The logger to report the result of exporting spans.
        public init(exportingTo exporter: SpanExporter, logger: Logger = Logger(label: "OTel")) {
            self.exporter = exporter
            self.logger = logger
        }

        public func processEndedSpan(_ span: OTel.RecordedSpan, on resource: OTel.Resource) {
            guard span.context.traceFlags.contains(.sampled) else { return }

            exporter.export([span], on: resource).whenComplete { result in
                guard logger.logLevel >= .debug else { return }

                var metadata: Logger.Metadata = [
                    "operation-name": .string(span.operationName),
                    "trace-id": .stringConvertible(span.context.traceID),
                    "span-id": .stringConvertible(span.context.spanID),
                ]

                switch result {
                case .success:
                    logger.debug("Exported span", metadata: metadata)
                case .failure(let error):
                    metadata["error"] = .string(String(describing: error))
                    logger.debug("Failed to export span", metadata: metadata)
                }
            }
        }
    }
}
