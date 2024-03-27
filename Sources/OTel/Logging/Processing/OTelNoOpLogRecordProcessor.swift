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

import ServiceContextModule

/// A log record processor that ignores all operations, used when no logs should be processed.
@_spi(Logging)
public struct OTelNoOpLogRecordProcessor: OTelLogRecordProcessor, CustomStringConvertible {
    public let description = "OTelNoOpLogRecordProcessor"

    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    /// Initialize a no-op log entry processor.
    public init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    public func run() async {
        for await _ in stream.cancelOnGracefulShutdown() {}
    }

    public func onEmit(_ log: OTelLogRecord) {
        // no-op
    }

    public func forceFlush() async throws {
        // no-op
    }
}
