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

import Dispatch
import class Foundation.ProcessInfo
import GRPC
import Lifecycle
import LifecycleNIOCompat
import Logging
import NIO
import OpenTelemetry
import OtlpGRPCSpanExporting
import Tracing
import TracingOpenTelemetrySupport

// MARK: - 1. Bootstrap Logging System

LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = ProcessInfo.processInfo.logLevel
    return handler
}

let logger = Logger(label: "example")

let lifecycle = ServiceLifecycle(configuration: ServiceLifecycle.Configuration(logger: logger))
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let otel = OTel(
    serviceName: "server",
    eventLoopGroup: eventLoopGroup,
    processor: OTel.SimpleSpanProcessor(
        exportingTo: OtlpGRPCSpanExporter(config: .init(eventLoopGroup: eventLoopGroup))
    )
)
let server = Server(eventLoopGroup: eventLoopGroup)

// MARK: - 2. Register EventLoopGroup

lifecycle.registerShutdown(label: "eventLoopGroup", .sync(eventLoopGroup.syncShutdownGracefully))

// MARK: - 3. Register Tracer

lifecycle.register(
    label: "otel",
    start: .eventLoopFuture {
        otel.start().always { result in
            guard case .success = result else { return }
            InstrumentationSystem.bootstrap(otel.tracer())
        }
    },
    shutdown: .eventLoopFuture(otel.shutdown)
)

// MARK: - 4. Register Application

lifecycle.register(label: "server", start: .eventLoopFuture(server.start), shutdown: .eventLoopFuture(server.shutdown))

// MARK: - 5. Start Lifecycle

lifecycle.start { error in
    if let error = error {
        logger.error("Failed starting: \(error)")
    } else {
        logger.info("[Server] started successfully")
    }
}

lifecycle.wait()

// MARK: - Server

final class Server {
    private let eventLoopGroup: EventLoopGroup

    init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }

    func start() -> EventLoopFuture<Void> {
        let serverSpan = InstrumentationSystem.tracer.startSpan("/languages/:language_name", baggage: .topLevel)
        serverSpan.attributes.http.method = "GET"
        serverSpan.attributes.http.flavor = "1.1"
        serverSpan.attributes.http.target = "/languages/swift"
        serverSpan.attributes.http.host = "server:8080"
        serverSpan.attributes.http.server.name = "server"
        serverSpan.attributes.net.host.port = 8080
        serverSpan.attributes.http.scheme = "http"
        serverSpan.attributes.http.server.route = "/languages/:language_name"
        serverSpan.attributes.http.server.clientIP = "0.0.0.0"
        serverSpan.attributes.net.peer.ip = "0.0.0.0"
        serverSpan.attributes.http.userAgent = "Example Browser"

        serverSpan.addEvent(SpanEvent(
            name: "Cached language not found, querying database",
            attributes: ["language": "swift"],
            at: .now() + .milliseconds(400)
        ))

        let dbSpan = InstrumentationSystem.tracer.startSpan(
            "SELECT languages",
            baggage: serverSpan.baggage,
            ofKind: .client,
            at: .now() + .milliseconds(410)
        )
        dbSpan.attributes.db.system = "mysql"
        dbSpan.attributes.db.connectionString = "Server=example;Database=example;"
        dbSpan.attributes.db.user = "hopefully_not_root"
        dbSpan.attributes.net.peer.ip = "0.0.0.0"
        dbSpan.attributes.net.peer.port = 3306
        dbSpan.attributes.net.transport = "IP.TCP"
        dbSpan.attributes.db.name = "example"
        dbSpan.attributes.db.statement = "SELECT * FROM languages WHERE name = ?"
        dbSpan.attributes.db.operation = "SELECT"
        dbSpan.attributes.db.sql.table = "languages"

        dbSpan.end(at: .now() + .milliseconds(1234))
        serverSpan.end(at: .now() + .milliseconds(1245))

        serverSpan.attributes.http.statusCode = 200

        return eventLoopGroup.next().makeSucceededVoidFuture()
    }

    func shutdown() -> EventLoopFuture<Void> {
        eventLoopGroup.next().makeSucceededVoidFuture()
    }
}
