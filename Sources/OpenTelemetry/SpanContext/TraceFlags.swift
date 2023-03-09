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

extension OTel {
    /// A set of flags denoting e.g. whether a span is sampled.
    ///
    /// - SeeAlso: [W3C TraceContext: Trace flags](https://www.w3.org/TR/2020/REC-trace-context-1-20200206/#trace-flags)
    public struct TraceFlags: OptionSet {
        /// The bit value of the given flags.
        public let rawValue: UInt8

        /// Initialize `TraceFlags` from the given bit value.
        ///
        /// - Parameter rawValue: The bit value mapping to a set of trace flags.
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        /// Indicates whether a span is sampled.
        ///
        /// - SeeAlso: [W3C TraceContext: Sampled flag](https://www.w3.org/TR/2020/REC-trace-context-1-20200206/#sampled-flag)
        public static let sampled = TraceFlags(rawValue: 1 << 0)
    }
}

extension OTel.TraceFlags: Sendable {}
