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
    struct SpanID {
        // 8-byte array
        public typealias Bytes = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

        private let _bytes: Bytes

        public init(bytes: Bytes) {
            _bytes = bytes
        }

        public var bytes: [UInt8] {
            withUnsafeBytes(of: _bytes, Array.init)
        }
    }
}

extension OTel.SpanID: CustomStringConvertible {
    public var description: String {
        String(decoding: hexBytes, as: UTF8.self)
    }

    public var hexBytes: [UInt8] {
        var asciiBytes: (UInt64, UInt64) = (0, 0)
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
            return Array(ptr)
        }
    }
}

extension OTel.SpanID: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._bytes.0 == rhs._bytes.0
            && lhs._bytes.1 == rhs._bytes.1
            && lhs._bytes.2 == rhs._bytes.2
            && lhs._bytes.3 == rhs._bytes.3
            && lhs._bytes.4 == rhs._bytes.4
            && lhs._bytes.5 == rhs._bytes.5
            && lhs._bytes.6 == rhs._bytes.6
            && lhs._bytes.7 == rhs._bytes.7
    }
}

extension OTel.SpanID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_bytes.0)
        hasher.combine(_bytes.1)
        hasher.combine(_bytes.2)
        hasher.combine(_bytes.3)
        hasher.combine(_bytes.4)
        hasher.combine(_bytes.5)
        hasher.combine(_bytes.6)
        hasher.combine(_bytes.7)
    }
}
