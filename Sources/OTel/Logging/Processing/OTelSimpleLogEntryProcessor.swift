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

@_spi(Logging)
public struct OTelSimpleLogEntryProcessor<Exporter: OTelLogEntryExporter>: OTelLogEntryProcessor {
    private let exporter: Exporter
    private let stream: AsyncStream<OTelLogEntry>
    private let continuation: AsyncStream<OTelLogEntry>.Continuation
    
    public init(exporter: Exporter) {
        self.exporter = exporter
        (stream, continuation) = AsyncStream.makeStream()
    }

    public func run() async throws {
        for try await log in stream.cancelOnGracefulShutdown() {
            do {
                try await exporter.export([log])
            } catch {
                // simple log processor does not attempt retries
            }
        }
    }

    public func onLog(_ log: OTelLogEntry) {
        continuation.yield(log)
    }

    public func forceFlush() async throws {
        try await exporter.forceFlush()
    }

    public func shutdown() async throws {
        await exporter.shutdown()
    }
}
