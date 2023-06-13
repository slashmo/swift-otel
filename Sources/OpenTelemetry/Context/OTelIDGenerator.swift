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

/// An ID generator generates random trace and span IDs on demand.
public protocol OTelIDGenerator {
    /// Get a generated trace ID.
    ///
    /// - Returns: A generated trace ID.
    mutating func traceID() -> OTelTraceID

    /// Get a generated span ID.
    ///
    /// - Returns: A generated span ID.
    mutating func spanID() -> OTelSpanID
}
