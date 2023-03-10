//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.Data
import class Foundation.ProcessInfo
import struct Foundation.URL
import GRPC
import Logging
import NIO
import OpenTelemetry

public final class OtlpGRPCLogRecordExporter: OTelLogRecordExporter {
    private let client: Opentelemetry_Proto_Collector_Logs_V1_LogsServiceNIOClient
    private let logger: Logger

    public init(config: OtlpGRPCSpanExporter.Config) {
        let channel = ClientConnection
            .insecure(group: config.eventLoopGroup)
            .connect(host: config.host, port: config.port)

        self.client = Opentelemetry_Proto_Collector_Logs_V1_LogsServiceNIOClient(
            channel: channel,
            defaultCallOptions: .init(timeLimit: .timeout(.seconds(10)))
        )
        self.logger = Logger(
            label: "OtlpGRPCLogRecordExporter",
            factory: { label in
                var handler = StreamLogHandler.standardOutput(label: label)
                handler.logLevel = .trace
                return handler
            }
        )
    }

    public func export<C: Collection>(_ batch: C) -> EventLoopFuture<Void> where C.Element == OTel.LogRecord {
        logger.trace("Exporting batch of log records", metadata: ["batch-size": .stringConvertible(batch.count)])

        return client.export(.init(batch))
            .response
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
