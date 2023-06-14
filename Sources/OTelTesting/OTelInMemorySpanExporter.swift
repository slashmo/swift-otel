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

/// An in-memory span exporter, collecting exported batches into ``OTelInMemorySpanExporter/exportedBatches``.
public final actor OTelInMemorySpanExporter: OTelSpanExporter {
    private(set) public var exportedBatches = [[OTelFinishedSpan]]()
    private(set) public var numberOfShutdowns = 0
    private(set) public var numberOfForceFlushes = 0

    public init() {}

    public func export(_ batch: some Collection<OTelFinishedSpan>) async throws {
        exportedBatches.append(Array(batch))
    }

    public func shutdown() async {
        numberOfShutdowns += 1
    }

    public func forceFlush() async throws {
        numberOfForceFlushes += 1
    }
}
