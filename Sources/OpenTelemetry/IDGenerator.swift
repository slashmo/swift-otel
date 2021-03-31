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

/// Responsible for generating trace and span ids.
public protocol OTelIDGenerator {
    /// Generate a new `OTel.TraceID`.
    mutating func generateTraceID() -> OTel.TraceID

    /// Generate a new `OTel.SpanID`.
    mutating func generateSpanID() -> OTel.SpanID
}
