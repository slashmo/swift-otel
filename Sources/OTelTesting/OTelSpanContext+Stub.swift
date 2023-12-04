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

import OTel

extension OTelSpanContext {
    /// A span context stub.
    ///
    /// - Parameters:
    ///   - traceID: Defaults to `OTelTraceID.allZeroes`.
    ///   - spanID: Defaults to `OTelSpanID.allZeroes`.
    ///   - parentSpanID: Defaults to `nil`.
    ///   - traceFlags: Defaults to no flags.
    ///   - traceState: Defaults to `nil`.
    ///   - isRemote: Defaults to `false`.
    ///
    /// - Returns: A span context stub.
    public static func stub(
        traceID: OTelTraceID = .allZeroes,
        spanID: OTelSpanID = .allZeroes,
        parentSpanID: OTelSpanID? = nil,
        traceFlags: OTelTraceFlags = [],
        traceState: OTelTraceState? = nil,
        isRemote: Bool = false
    ) -> OTelSpanContext {
        OTelSpanContext(
            traceID: traceID,
            spanID: spanID,
            parentSpanID: parentSpanID,
            traceFlags: traceFlags,
            traceState: traceState,
            isRemote: isRemote
        )
    }
}
