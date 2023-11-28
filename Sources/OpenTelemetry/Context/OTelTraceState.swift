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
    private var items: [Item]

    /// Create a trace state with the given vendor-value pairs.
    ///
    /// - Parameter items: The vendor-value pairs stored in the trace state.
    public init(items: [Item]) {
        self.items = items
    }

    /// A single vendor-value pair stored in the trace state.
    public struct Item: Sendable, Hashable {
        /// The entry's vendor.
        public let vendor: String
        /// The entry's value.
        public let value: String

        /// Create a new vendor-value pair.
        ///
        /// - Parameters:
        ///   - vendor: The vendor.
        ///   - value: The value.
        public init(vendor: String, value: String) {
            self.vendor = vendor
            self.value = value
        }
    }
}

extension OTelTraceState: CustomStringConvertible {
    public var description: String {
        items.map { "\($0.vendor)=\($0.value)" }.joined(separator: ",")
    }
}

extension OTelTraceState: Hashable {}
extension OTelTraceState: Sendable {}
