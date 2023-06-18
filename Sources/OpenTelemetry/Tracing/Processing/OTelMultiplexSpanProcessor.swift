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

import ServiceContextModule

/// A pseudo-``OTelSpanProcessor`` that may be used to process using multiple other ``OTelSpanProcessor``s.
public struct OTelMultiplexSpanProcessor: OTelSpanProcessor {
    private let processors: [any OTelSpanProcessor]

    /// Create an ``OTelMultiplexSpanProcessor``.
    ///
    /// - Parameter processors: An array of ``OTelSpanProcessor``s, each of which will be invoked on start and end of spans.
    /// Processors are called sequentially and the order of this array defines the order in which they're being called.
    public init(processors: [any OTelSpanProcessor]) {
        self.processors = processors
    }

    public func onStart(_ span: OTelSpan, parentContext: ServiceContext) async {
        for processor in processors {
            await processor.onStart(span, parentContext: parentContext)
        }
    }

    public func onEnd(_ span: OTelFinishedSpan) async {
        for processor in processors {
            await processor.onEnd(span)
        }
    }

    public func forceFlush() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for processor in processors {
                group.addTask { try await processor.forceFlush() }
            }

            try await group.waitForAll()
        }
    }

    public func shutdown() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for processor in processors {
                group.addTask { try await processor.shutdown() }
            }

            try await group.waitForAll()
        }
    }
}
