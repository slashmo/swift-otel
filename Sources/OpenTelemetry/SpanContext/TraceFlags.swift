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
    struct TraceFlags: OptionSet {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        /// [W3C TraceContext: Sampled flag](https://www.w3.org/TR/2020/REC-trace-context-1-20200206/#sampled-flag)
        public static let sampled = TraceFlags(rawValue: 1 << 0)
    }
}
