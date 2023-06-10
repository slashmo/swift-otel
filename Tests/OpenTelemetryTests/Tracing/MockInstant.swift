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

import Tracing

struct MockInstant: TracerInstant {
    var nanosecondsSinceEpoch: UInt64

    static func < (lhs: MockInstant, rhs: MockInstant) -> Bool {
        lhs.nanosecondsSinceEpoch < rhs.nanosecondsSinceEpoch
    }
}

extension TracerInstant where Self == MockInstant {
    static func constant(_ nanosecondsSinceEpoch: UInt64) -> MockInstant {
        MockInstant(nanosecondsSinceEpoch: nanosecondsSinceEpoch)
    }
}
