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

import NIOConcurrencyHelpers

/// The default ID generator,
/// based on a [`RandomNumberGenerator`](https://developer.apple.com/documentation/swift/randomnumbergenerator).
public struct OTelRandomIDGenerator<NumberGenerator: RandomNumberGenerator & Sendable>: OTelIDGenerator {
    private let randomNumberGenerator: NIOLockedValueBox<NumberGenerator>

    /// Create a random ID generator with a given random number generator.
    ///
    /// - Parameter randomNumberGenerator: The random number generator, defaults to
    /// [`SystemRandomNumberGenerator`](https://developer.apple.com/documentation/swift/systemrandomnumbergenerator)
    public init(randomNumberGenerator: NumberGenerator) {
        self.randomNumberGenerator = NIOLockedValueBox(randomNumberGenerator)
    }

    public func nextTraceID() -> OTelTraceID {
        var bytes: OTelTraceID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &bytes) { ptr in
            ptr.storeBytes(of: randomNumberGenerator.withLockedValue { $0.next() }.bigEndian, as: UInt64.self)
            ptr.storeBytes(
                of: randomNumberGenerator.withLockedValue { $0.next() }.bigEndian,
                toByteOffset: 8,
                as: UInt64.self
            )
        }
        return OTelTraceID(bytes: bytes)
    }

    public func nextSpanID() -> OTelSpanID {
        var bytes: OTelSpanID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &bytes) { ptr in
            ptr.storeBytes(of: randomNumberGenerator.withLockedValue { $0.next() }.bigEndian, as: UInt64.self)
        }
        return OTelSpanID(bytes: bytes)
    }
}

extension OTelRandomIDGenerator where NumberGenerator == SystemRandomNumberGenerator {
    public init() {
        randomNumberGenerator = NIOLockedValueBox(SystemRandomNumberGenerator())
    }
}
