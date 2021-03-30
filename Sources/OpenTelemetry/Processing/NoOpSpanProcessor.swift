//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2021 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public extension OTel {
    /// A no-op span processor that simply ignores the given spans.
    struct NoOpSpanProcessor: SpanProcessor {
        /// Initialize a new no-op processor.
        public init() {}

        public func processEndedSpan(_ span: OTel.RecordedSpan, on resource: OTel.Resource) {}
    }
}
