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

import OpenTelemetry

/// A span exporter, streaming exported batches via an async sequence.
public final actor OTelStreamingSpanExporter: OTelSpanExporter {
    public let batches: AsyncStream<[OTelFinishedSpan]>
    private let batchContinuation: AsyncStream<[OTelFinishedSpan]>.Continuation

    public let errors: AsyncStream<any Error>
    private let errorContinuation: AsyncStream<any Error>.Continuation

    private let exportDelayInNanoseconds: UInt64

    public private(set) var numberOfShutdowns = 0
    public private(set) var numberOfForceFlushes = 0

    public init(exportDelayInNanoseconds: UInt64 = 0) {
        self.exportDelayInNanoseconds = exportDelayInNanoseconds
        (batches, batchContinuation) = AsyncStream<[OTelFinishedSpan]>.makeStream()
        (errors, errorContinuation) = AsyncStream<any Error>.makeStream()
    }

    public func export(_ batch: some Collection<OTelFinishedSpan>) async throws {
        do {
            try await Task.sleep(nanoseconds: exportDelayInNanoseconds)
            batchContinuation.yield(Array(batch))
        } catch {
            errorContinuation.yield(error)
        }
    }

    public func shutdown() async {
        numberOfShutdowns += 1
    }

    public func forceFlush() async throws {
        numberOfForceFlushes += 1
    }
}
