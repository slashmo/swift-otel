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

/// A span processor that ignores all operations, used when no spans should be processed.
public struct OTelNoOpSpanProcessor: OTelSpanProcessor {
    /// Initialize a no-op span processor.
    public init() {}

    public func run() async throws {
        while !Task.isCancelled {}
    }

    public func onStart(_ span: OTelSpan, parentContext: ServiceContext) {
        // no-op
    }

    public func onEnd(_ span: OTelFinishedSpan) {
        // no-op
    }

    public func forceFlush() async throws {
        // no-op
    }
}
