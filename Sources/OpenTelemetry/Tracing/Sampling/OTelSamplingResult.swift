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

import Tracing

/// The result returned by ``OTelSampler``s.
public struct OTelSamplingResult: Equatable {
    /// The decision on whether a span should be recorded/sampled.
    public let decision: Decision
    
    /// Additional attributes describing the sampling decision to be included in the span's attributes.
    public let attributes: SpanAttributes

    /// A decision on whether a span should be recorded/sampled.
    ///
    /// | Decision | Received by processor(s) | Received by exporter(s) |
    /// | --- | --- | --- |
    /// | ``Decision/drop`` | ❌ | ❌ |
    /// | ``Decision/record`` | ✅ | ❌ |
    /// | ``Decision/recordAndSample`` | ✅ | ✅ |
    public enum Decision: Equatable {
        /// Don't record the span and drop all events and attributes.
        case drop

        /// Process the span but do not export it.
        case record

        /// Process and export the span.
        case recordAndSample
    }
}
