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
import ServiceContextModule

/// An in-memory span processor, collecting started spans into ``OTelInMemorySpanProcessor/startedSpans``
/// and finished spans into ``OTelInMemorySpanProcessor/finishedSpans``.
public final actor OTelInMemorySpanProcessor: OTelSpanProcessor {
    private(set) public var startedSpans = [(span: OTelSpan, parentContext: ServiceContext)]()
    private(set) public var finishedSpans = [OTelFinishedSpan]()
    private(set) public var numberOfForceFlushes = 0
    private(set) public var numberOfShutdowns = 0

    public init() {}

    public func onStart(_ span: OTelSpan, parentContext: ServiceContext) async {
        startedSpans.append((span, parentContext))
    }

    public func onEnd(_ span: OTelFinishedSpan) async {
        finishedSpans.append(span)
    }

    public func forceFlush() async throws {
        numberOfForceFlushes += 1
    }

    public func shutdown() async throws {
        numberOfShutdowns += 1
    }
}
