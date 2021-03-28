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
import Lifecycle
import LifecycleNIOCompat
import Logging
import NIO
import OpenTelemetry
import Tracing

// MARK: - 1. Bootstrap Logging System

LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = ProcessInfo.processInfo.logLevel
    return handler
}

let logger = Logger(label: "example")

let lifecycle = ServiceLifecycle(configuration: ServiceLifecycle.Configuration(logger: logger))
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let otel = OTel(serviceName: "server", eventLoopGroup: eventLoopGroup)
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
        eventLoopGroup.next().makeSucceededVoidFuture()
    }

    func shutdown() -> EventLoopFuture<Void> {
        eventLoopGroup.next().makeSucceededVoidFuture()
    }
}
