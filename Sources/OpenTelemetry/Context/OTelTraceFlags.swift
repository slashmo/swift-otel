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

/// An 8-bit field controlling tracing flags such as sampling.
public struct OTelTraceFlags: OptionSet {
    /// The bit value representing the given flags.
    public let rawValue: UInt8
    
    /// Create an ``OTelTraceFlags`` from the given bit value representation.
    ///
    /// - Parameter rawValue: The bit value representing zero or more trace flags.
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    /// Indicates whether a span is sampled.
    ///
    /// [W3C TraceContext: Sampled flag](https://www.w3.org/TR/trace-context-1/#sampled-flag)
    public static let sampled = OTelTraceFlags(rawValue: 1)
}

extension OTelTraceFlags: Sendable {}
