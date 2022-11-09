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

extension OtlpGRPCExporter {
    /// Configures an `OtlpGRPCSpanExporter` through arguments and environment variables.
    ///
    /// ## Priority
    /// Arguments passed to the initializer have a **higher priority** than environment variables.
    ///
    /// ## Environment variables
    ///
    /// The following environment variables may be used to configure the exporter instead of specifying them in code:
    ///
    /// - `OTEL_EXPORTER_OTLP_ENDPOINT`: Must be a valid URL which contains both host and port of the OTel collector.
    public struct Config {
        let eventLoopGroup: EventLoopGroup
        let host: String
        let port: Int
        let logger: Logger

        /// Initialize a configuration to pass to an `OtlpGRPCSpanExporter`.
        ///
        /// - Parameters:
        ///   - eventLoopGroup: The event loop group the gRPC client connection should be running on.
        ///   - host: The OTel collector host, defaults to `localhost` if not provided and `OTEL_EXPORTER_OTLP_ENDPOINT` is not set.
        ///   - port: The OTel collector port, defaults to `4317` if not provided and `OTEL_EXPORTER_OTLP_ENDPOINT` is not set.
        ///   - logger: The logger to be used, defaults to "OtlpGRPCSpanExporter".
        public init(
            eventLoopGroup: EventLoopGroup,
            host: String? = nil,
            port: UInt? = nil,
            logger: Logger = Logger(label: "OtlpGRPCSpanExporter")
        ) {
            self.init(
                eventLoopGroup: eventLoopGroup,
                host: host,
                port: port,
                logger: logger,
                environment: ProcessInfo.processInfo.environment
            )
        }

        init(
            eventLoopGroup: EventLoopGroup,
            host: String?,
            port: UInt?,
            logger: Logger,
            environment: [String: String]
        ) {
            self.eventLoopGroup = eventLoopGroup
            self.logger = logger

            if let host = host {
                self.host = host
                self.port = port.map { Int($0) } ?? 4317
            } else if let port = port {
                self.host = "localhost"
                self.port = Int(port)
            } else if let endpoint = environment["OTEL_EXPORTER_OTLP_ENDPOINT"],
                      let endpointURL = URL(string: endpoint),
                      let host = endpointURL.host,
                      let port = endpointURL.port
            {
                self.host = host
                self.port = port
            } else {
                self.host = "localhost"
                self.port = 4317
            }
        }
    }
}
