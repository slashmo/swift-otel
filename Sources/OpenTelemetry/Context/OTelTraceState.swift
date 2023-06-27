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

/// Provides additional vendor-specific trace identification information across different distributed tracing systems.
///
/// [W3C TraceContext: trace-state](https://www.w3.org/TR/trace-context-1/#tracestate-header)
public struct OTelTraceState {
    /// The underlying storage for vendor-value trace state pairs.
    public typealias Storage = [(vendor: String, value: String)]

    private var storage: Storage

    /// Create a trace state with the given vendor-value pairs.
    ///
    /// - Parameter items: The vendor-value pairs stored in the trace state.
    public init(items: Storage) {
        storage = items
    }
}

extension OTelTraceState: Equatable {
    public static func == (lhs: OTelTraceState, rhs: OTelTraceState) -> Bool {
        guard lhs.storage.count == rhs.storage.count else { return false }

        return lhs.storage.enumerated().allSatisfy { offset, lhsElement in
            let rhsElement = rhs.storage[offset]
            return rhsElement.vendor == lhsElement.vendor && rhsElement.value == lhsElement.value
        }
    }
}

extension OTelTraceState: CustomStringConvertible {
    public var description: String {
        storage.map { "\($0)=\($1)" }.joined(separator: ",")
    }
}

extension OTelTraceState: Sendable {}
