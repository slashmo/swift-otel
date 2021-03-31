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

import class Foundation.ProcessInfo
import struct Foundation.URL
import GRPC
import Logging
import NIO
@_exported import OpenTelemetry

/// A span exporter which sends spans to an OTel collector via gRPC in the OpenTelemetry protocol (OTLP).
///
/// - Warning: In order for this exporter to work you must have a running instance of the OTel collector deployed.
/// Check out the ['OTel Collector: Getting Started'](https://opentelemetry.io/docs/collector/getting-started/) docs in case you don't have
/// the collector running yet.
public final class OtlpGRPCSpanExporter: OTelSpanExporter {
    private let client: Opentelemetry_Proto_Collector_Trace_V1_TraceServiceClient
    private let logger: Logger

    /// Initialize a new span exporter with the given configuration.
    ///
    /// - Parameter config: The config to be applied to the exporter.
    public init(config: Config) {
        let channel = ClientConnection
            .insecure(group: config.eventLoopGroup)
            .connect(host: config.host, port: config.port)

        self.client = Opentelemetry_Proto_Collector_Trace_V1_TraceServiceClient(
            channel: channel,
            defaultCallOptions: .init(timeLimit: .timeout(.seconds(10)))
        )
        self.logger = config.logger
    }

    public func export(_ batch: ArraySlice<OTel.RecordedSpan>, on resource: OTel.Resource) -> EventLoopFuture<Void> {
        logger.trace("Exporting batch of spans", metadata: ["batch-size": .stringConvertible(batch.count)])

        let request = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with { request in
            request.resourceSpans = [.init(resource: resource, spans: batch)]
        }

        return client.export(request).response
            .always { [weak self] result in
                switch result {
                case .success:
                    self?.logger.trace("Successfully exported batch")
                case .failure(let error):
                    self?.logger.debug("Failed to export batch", metadata: [
                        "error": .string(String(describing: error)),
                    ])
                }
            }
            .map { _ in }
    }

    public func shutdownGracefully() -> EventLoopFuture<Void> {
        client.channel.close()
    }
}
