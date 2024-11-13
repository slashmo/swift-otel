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

public struct StubInstant: TracerInstant {
    public var nanosecondsSinceEpoch: UInt64

    public static func < (lhs: StubInstant, rhs: StubInstant) -> Bool {
        lhs.nanosecondsSinceEpoch < rhs.nanosecondsSinceEpoch
    }
}

extension TracerInstant where Self == StubInstant {
    /// Create a tracer instant with the given nanoseconds since epoch.
    ///
    /// - Parameter nanosecondsSinceEpoch: The fixed nanoseconds since epoch.
    /// - Returns: A tracer instant with the given nanoseconds since epoch.
    public static func constant(_ nanosecondsSinceEpoch: UInt64) -> StubInstant {
        StubInstant(nanosecondsSinceEpoch: nanosecondsSinceEpoch)
    }
}
