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
    /// Provides additional vendor-specific trace identification information across different distributed tracing systems.
    ///
    /// - SeeAlso: [W3C TraceContext: TraceState](https://www.w3.org/TR/2020/REC-trace-context-1-20200206/#tracestate-header)
    struct TraceState {
        typealias Storage = [(vendor: String, value: String)]

        private var _storage: Storage

        init(_ storage: Storage) {
            _storage = storage
        }
    }
}

extension OTel.TraceState: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs._storage.count == rhs._storage.count else { return false }

        return lhs._storage.enumerated().allSatisfy { offset, element in
            rhs._storage[offset].vendor == element.vendor && rhs._storage[offset].value == element.value
        }
    }
}
