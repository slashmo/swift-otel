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
public final class OtlpGRPCExporter {
    private let client: ClientConnection
    private let traceClient: Opentelemetry_Proto_Collector_Trace_V1_TraceServiceNIOClient
    private let logClient: Opentelemetry_Proto_Collector_Logs_V1_LogsServiceNIOClient
    private let metricsClient: Opentelemetry_Proto_Collector_Metrics_V1_MetricsServiceNIOClient
    private let logger: Logger
    
    /// Initialize a new span exporter with the given configuration.
    ///
    /// - Parameter config: The config to be applied to the exporter.
    public init(config: Config) {
        let client = ClientConnection
            .insecure(group: config.eventLoopGroup)
            .connect(host: config.host, port: config.port)
        
        self.traceClient = .init(
            channel: client,
            defaultCallOptions: .init(timeLimit: .timeout(.seconds(10)))
        )
        
        self.logClient = .init(
            channel: client,
            defaultCallOptions: .init(timeLimit: .timeout(.seconds(10)))
        )
        
        self.metricsClient = .init(
            channel: client,
            defaultCallOptions: .init(timeLimit: .timeout(.seconds(10)))
        )
        
        self.logger = config.logger
        self.client = client
    }
    
    public func shutdownGracefully() -> EventLoopFuture<Void> {
        client.close()
    }
}

extension OtlpGRPCExporter: OTelSpanExporter {
    public func exportSpans<C: Collection>(_ batch: C) -> EventLoopFuture<Void> where C.Element == OTel.RecordedSpan {
        return traceClient.export(.init(batch)).response.map { _ in }
    }
}

extension OtlpGRPCExporter: OTelLogExporter {
    public func exportLogs<C>(_ batch: C) -> EventLoopFuture<Void> where C : Collection, C.Element == OTel.RecordedLog {
        return logClient.export(.init(batch)).response.map { _ in }
    }
}

extension OtlpGRPCExporter: OTelMetricsExporter {
    public func exportMetrics<C>(_ batch: C) -> EventLoopFuture<Void> where C : Collection, C.Element == OTel.RecordedMetric {
        return metricsClient.export(.init(batch)).response.map { _ in }
    }
}
