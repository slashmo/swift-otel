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

import struct Foundation.URL
import GRPC
import Logging
import NIO
import NIOHPACK
import NIOSSL
import OTLPCore
import OpenTelemetry
import Tracing

/// A span exporter emitting span batches to an OTel collector via gRPC.
public final class OTLPGRPCSpanExporter: OTelSpanExporter {
    private let configuration: OTLPGRPCSpanExporterConfiguration
    private let connection: ClientConnection
    private let client: Opentelemetry_Proto_Collector_Trace_V1_TraceServiceAsyncClient
    private let logger = Logger(label: String(describing: OTLPGRPCSpanExporter.self))

    /// Create a OTLP gRPC span exporter.
    ///
    /// - Parameters:
    ///   - configuration: The exporters configuration.
    ///   - group: The NIO event loop group to run the exporter in.
    ///   - requestLogger: Logs info about the underlying gRPC requests. Defaults to disabled, i.e. not emitting any logs.
    ///   - backgroundActivityLogger: Logs info about the underlying gRPC connection. Defaults to disabled, i.e. not emitting any logs.
    public init(
        configuration: OTLPGRPCSpanExporterConfiguration,
        group: any EventLoopGroup,
        requestLogger: Logger = ._otelDisabled,
        backgroundActivityLogger: Logger = ._otelDisabled
    ) {
        self.configuration = configuration

        var connectionConfiguration = ClientConnection.Configuration.default(
            target: .host(configuration.endpoint.host, port: configuration.endpoint.port),
            eventLoopGroup: group
        )

        if configuration.endpoint.isInsecure {
            logger.debug("Using insecure connection.", metadata: [
                "host": "\(configuration.endpoint.host)",
                "port": "\(configuration.endpoint.port)",
            ])
        }

        // TODO: Support OTEL_EXPORTER_OTLP_CERTIFICATE
        // TODO: Support OTEL_EXPORTER_OTLP_CLIENT_KEY
        // TODO: Support OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE

        var headers = configuration.headers
        if !headers.isEmpty {
            logger.trace("Configured custom request headers.", metadata: [
                "keys": .array(headers.map({ "\($0.name)" })),
            ])
        }
        headers.replaceOrAdd(name: "user-agent", value: "OTel-OTLP-Exporter-Swift/\(OTelLibrary.version)")

        connectionConfiguration.backgroundActivityLogger = backgroundActivityLogger
        connection = ClientConnection(configuration: connectionConfiguration)

        client = Opentelemetry_Proto_Collector_Trace_V1_TraceServiceAsyncClient(
            channel: connection,
            defaultCallOptions: .init(customMetadata: headers, logger: requestLogger)
        )
    }

    public func export(_ batch: some Collection<OpenTelemetry.OTelFinishedSpan>) async throws {
        if case .shutdown = connection.connectivity.state {
            logger.error("Attempted to export batch while already being shut down.")
            throw OTelSpanExporterAlreadyShutDownError()
        }

        let request = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with { request in
            request.resourceSpans = [
                .with { resourceSpans in
                    // TODO: Add resource
                    resourceSpans.resource = .with { resource in
                        resource.attributes = .init(["service.name": "test"])
                    }

                    resourceSpans.scopeSpans = [
                        .with { scopeSpans in
                            scopeSpans.scope = .with { scope in
                                scope.name = "swift-otel"
                                scope.version = OTelLibrary.version
                            }
                            scopeSpans.spans = batch.map(Opentelemetry_Proto_Trace_V1_Span.init)
                        }
                    ]
                }
            ]
        }

        _ = try await client.export(request)
    }

    /// ``OTLPGRPCSpanExporter`` sends batches of spans as soon as they are received, so this method is a no-op.
    public func forceFlush() async throws {}

    public func shutdown() async {
        let promise = connection.eventLoop.makePromise(of: Void.self)

        connection.closeGracefully(deadline: .now() + .milliseconds(500), promise: promise)

        try? await promise.futureResult.get()
    }
}
