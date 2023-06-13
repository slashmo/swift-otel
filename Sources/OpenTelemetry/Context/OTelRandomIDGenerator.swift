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

/// The default ID generator,
/// based on a [`RandomNumberGenerator`](https://developer.apple.com/documentation/swift/randomnumbergenerator).
public struct OTelRandomIDGenerator: OTelIDGenerator {
    private var randomNumberGenerator: any RandomNumberGenerator

    /// Create a random ID generator with a given random number generator.
    ///
    /// - Parameter randomNumberGenerator: The random number generator, defaults to
    /// [`SystemRandomNumberGenerator`](https://developer.apple.com/documentation/swift/systemrandomnumbergenerator)
    public init(randomNumberGenerator: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.randomNumberGenerator = randomNumberGenerator
    }

    public mutating func traceID() -> OTelTraceID {
        var bytes: OTelTraceID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &bytes) { ptr in
            ptr.storeBytes(of: randomNumberGenerator.next().bigEndian, as: UInt64.self)
            ptr.storeBytes(of: randomNumberGenerator.next().bigEndian, toByteOffset: 8, as: UInt64.self)
        }
        return OTelTraceID(bytes: bytes)
    }

    public mutating func spanID() -> OTelSpanID {
        var bytes: OTelSpanID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &bytes) { ptr in
            ptr.storeBytes(of: randomNumberGenerator.next().bigEndian, as: UInt64.self)
        }
        return OTelSpanID(bytes: bytes)
    }
}
