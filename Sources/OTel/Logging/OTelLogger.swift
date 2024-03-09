//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AsyncAlgorithms
import Logging
import NIOConcurrencyHelpers
import ServiceLifecycle
import Logging
import Tracing

@globalActor fileprivate actor OTelLoggingActor {
    static let shared = OTelLoggingActor()
}

@_spi(Logging)
@available(macOS 14, *)
public final class OTelStreamingLogger: Service, Sendable, LogHandler {
    private let exporter: OTelLogExporter
    var resource: OTelResource
    private let logMessages: AsyncStream<OTelLog>
    private let logMessagesContinuation: AsyncStream<OTelLog>.Continuation
    public var metadata: Logging.Logger.Metadata
    public var logLevel: Logging.Logger.Level

    public init(
        resource: OTelResource,
        exporter: OTelLogExporter,
        logLevel: Logger.Level,
        metadata: Logger.Metadata = [:]
    ) {
        self.resource = resource
        self.exporter = exporter
        self.logLevel = logLevel
        self.metadata = metadata
        (self.logMessages, self.logMessagesContinuation) = AsyncStream.makeStream(bufferingPolicy: .unbounded)
    }

    public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public func run() async throws {
        await withDiscardingTaskGroup { taskGroup in
            for await message in logMessages.cancelOnGracefulShutdown() {
                taskGroup.addTask {
                    do {
                        try await self.exporter.export([message])
                    } catch {
                        // TODO: Do we report this? What do we do?
                    }
                }
            }
        }
    }
    
    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let instant = DefaultTracerClock().now

        let message = OTelLog(
            body: message.description,
            level: level,
            metadata: metadata,
            timeNanosecondsSinceEpoch: instant.nanosecondsSinceEpoch
        )

        logMessagesContinuation.yield(message)
    }
}
