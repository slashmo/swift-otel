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
    struct TraceID {
        // 16-byte array
        public typealias Bytes = (
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
        )

        private let _bytes: Bytes

        public init(bytes: Bytes) {
            _bytes = bytes
        }

        public var bytes: [UInt8] {
            withUnsafeBytes(of: _bytes, Array.init)
        }
    }
}

extension OTel.TraceID: CustomStringConvertible {
    public var description: String {
        String(decoding: hexBytes, as: UTF8.self)
    }

    public var hexBytes: [UInt8] {
        var asciiBytes: (UInt64, UInt64, UInt64, UInt64) = (0, 0, 0, 0)
        return withUnsafeMutableBytes(of: &asciiBytes) { ptr in
            ptr[0] = OTel.Hex.lookup[Int(_bytes.0 >> 4)]
            ptr[1] = OTel.Hex.lookup[Int(_bytes.0 & 0x0F)]
            ptr[2] = OTel.Hex.lookup[Int(_bytes.1 >> 4)]
            ptr[3] = OTel.Hex.lookup[Int(_bytes.1 & 0x0F)]
            ptr[4] = OTel.Hex.lookup[Int(_bytes.2 >> 4)]
            ptr[5] = OTel.Hex.lookup[Int(_bytes.2 & 0x0F)]
            ptr[6] = OTel.Hex.lookup[Int(_bytes.3 >> 4)]
            ptr[7] = OTel.Hex.lookup[Int(_bytes.3 & 0x0F)]
            ptr[8] = OTel.Hex.lookup[Int(_bytes.4 >> 4)]
            ptr[9] = OTel.Hex.lookup[Int(_bytes.4 & 0x0F)]
            ptr[10] = OTel.Hex.lookup[Int(_bytes.5 >> 4)]
            ptr[11] = OTel.Hex.lookup[Int(_bytes.5 & 0x0F)]
            ptr[12] = OTel.Hex.lookup[Int(_bytes.6 >> 4)]
            ptr[13] = OTel.Hex.lookup[Int(_bytes.6 & 0x0F)]
            ptr[14] = OTel.Hex.lookup[Int(_bytes.7 >> 4)]
            ptr[15] = OTel.Hex.lookup[Int(_bytes.7 & 0x0F)]
            ptr[16] = OTel.Hex.lookup[Int(_bytes.8 >> 4)]
            ptr[17] = OTel.Hex.lookup[Int(_bytes.8 & 0x0F)]
            ptr[18] = OTel.Hex.lookup[Int(_bytes.9 >> 4)]
            ptr[19] = OTel.Hex.lookup[Int(_bytes.9 & 0x0F)]
            ptr[20] = OTel.Hex.lookup[Int(_bytes.10 >> 4)]
            ptr[21] = OTel.Hex.lookup[Int(_bytes.10 & 0x0F)]
            ptr[22] = OTel.Hex.lookup[Int(_bytes.11 >> 4)]
            ptr[23] = OTel.Hex.lookup[Int(_bytes.11 & 0x0F)]
            ptr[24] = OTel.Hex.lookup[Int(_bytes.12 >> 4)]
            ptr[25] = OTel.Hex.lookup[Int(_bytes.12 & 0x0F)]
            ptr[26] = OTel.Hex.lookup[Int(_bytes.13 >> 4)]
            ptr[27] = OTel.Hex.lookup[Int(_bytes.13 & 0x0F)]
            ptr[28] = OTel.Hex.lookup[Int(_bytes.14 >> 4)]
            ptr[29] = OTel.Hex.lookup[Int(_bytes.14 & 0x0F)]
            ptr[30] = OTel.Hex.lookup[Int(_bytes.15 >> 4)]
            ptr[31] = OTel.Hex.lookup[Int(_bytes.15 & 0x0F)]
            return Array(ptr)
        }
    }
}

extension OTel.TraceID: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._bytes.0 == rhs._bytes.0
            && lhs._bytes.1 == rhs._bytes.1
            && lhs._bytes.2 == rhs._bytes.2
            && lhs._bytes.3 == rhs._bytes.3
            && lhs._bytes.4 == rhs._bytes.4
            && lhs._bytes.5 == rhs._bytes.5
            && lhs._bytes.6 == rhs._bytes.6
            && lhs._bytes.7 == rhs._bytes.7
            && lhs._bytes.8 == rhs._bytes.8
            && lhs._bytes.9 == rhs._bytes.9
            && lhs._bytes.10 == rhs._bytes.10
            && lhs._bytes.11 == rhs._bytes.11
            && lhs._bytes.12 == rhs._bytes.12
            && lhs._bytes.13 == rhs._bytes.13
            && lhs._bytes.14 == rhs._bytes.14
            && lhs._bytes.15 == rhs._bytes.15
    }
}

extension OTel.TraceID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_bytes.0)
        hasher.combine(_bytes.1)
        hasher.combine(_bytes.2)
        hasher.combine(_bytes.3)
        hasher.combine(_bytes.4)
        hasher.combine(_bytes.5)
        hasher.combine(_bytes.6)
        hasher.combine(_bytes.7)
        hasher.combine(_bytes.8)
        hasher.combine(_bytes.9)
        hasher.combine(_bytes.10)
        hasher.combine(_bytes.11)
        hasher.combine(_bytes.12)
        hasher.combine(_bytes.13)
        hasher.combine(_bytes.14)
        hasher.combine(_bytes.15)
    }
}
