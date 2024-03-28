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

/// A span processor that ignores all operations, used when no spans should be processed.
@_spi(Logging)
public struct OTelNoOpLogEntryProcessor: OTelLogEntryProcessor, CustomStringConvertible {
    public let description = "OTelNoOpSpanProcessor"

    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    /// Initialize a no-op span processor.
    public init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    public func run() async {
        for await _ in stream.cancelOnGracefulShutdown() {}
    }

    public func onLog(_ log: OTelLogEntry) {
        // no-op
    }

    public func forceFlush() async throws {
        // no-op
    }
}
