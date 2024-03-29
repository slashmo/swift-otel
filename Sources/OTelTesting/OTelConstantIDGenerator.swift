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

public struct OTelConstantIDGenerator: OTelIDGenerator {
    private let _traceID: OTelTraceID
    private let _spanID: OTelSpanID

    public init(traceID: OTelTraceID, spanID: OTelSpanID) {
        _traceID = traceID
        _spanID = spanID
    }

    public func nextTraceID() -> OTelTraceID {
        _traceID
    }

    public func nextSpanID() -> OTelSpanID {
        _spanID
    }
}
