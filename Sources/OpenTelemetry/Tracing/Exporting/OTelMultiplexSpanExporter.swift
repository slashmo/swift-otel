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

/// A pseudo-``OTelSpanExporter`` that may be used to export using multiple other ``OTelSpanExporter``s.
public struct OTelMultiplexSpanExporter: OTelSpanExporter {
    private let exporters: [any OTelSpanExporter]
    
    /// Initialize a ``OTelNoOpSpanExporter``.
    ///
    /// - Parameter exporters: An array of ``OTelSpanExporter``s, each of which will receive the exported batches.
    public init(exporters: [any OTelSpanExporter]) {
        self.exporters = exporters
    }

    public func export(_ batch: some Collection<OTelFinishedSpan>) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for exporter in exporters {
                group.addTask { try await exporter.export(batch) }
            }

            try await group.waitForAll()
        }
    }

    public func shutdown() async {
        await withTaskGroup(of: Void.self) { group in
            for exporter in exporters {
                group.addTask { await exporter.shutdown() }
            }
        }
    }

    public func forceFlush() async throws {
        await withThrowingTaskGroup(of: Void.self) { group in
            for exporter in exporters {
                group.addTask { try await exporter.forceFlush() }
            }
        }
    }
}
