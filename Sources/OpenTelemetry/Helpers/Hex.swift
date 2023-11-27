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

/// A collection of utilities when working with hex strings.
enum Hex {
    /// A lockup table for quick conversion of bytes to hex-bytes.
    static let lookup = [
        UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"),
        UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"),
        UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "a"), UInt8(ascii: "b"),
        UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f"),
    ]

    /// Convert the given ASCII bytes into bytes stored in the given target.
    ///
    /// - Warning: The target must be exactly half the size of the ASCII bytes.
    ///
    /// - Parameters:
    ///   - ascii: The ASCII bytes to convert.
    ///   - target: The pointer to store the converted bytes into.
    static func convert<T>(
        _ ascii: T,
        toBytes target: UnsafeMutableRawBufferPointer
    ) where T: RandomAccessCollection, T.Element == UInt8 {
        assert(ascii.count / 2 == target.count, "Target needs half as much space as ascii")

        var source = ascii.makeIterator()
        var targetIndex = 0

        while let major = source.next(), let minor = source.next() {
            var byte: UInt8 = 0

            switch major {
            case UInt8(ascii: "0") ... UInt8(ascii: "9"):
                byte = (major - UInt8(ascii: "0")) << 4
            case UInt8(ascii: "a") ... UInt8(ascii: "f"):
                byte = (major - UInt8(ascii: "a") + 10) << 4
            default:
                preconditionFailure()
            }

            switch minor {
            case UInt8(ascii: "0") ... UInt8(ascii: "9"):
                byte |= (minor - UInt8(ascii: "0"))
            case UInt8(ascii: "a") ... UInt8(ascii: "f"):
                byte |= (minor - UInt8(ascii: "a") + 10)
            default:
                preconditionFailure()
            }

            target[targetIndex] = byte
            targetIndex += 1
        }
    }
}
