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

/// Uniquely identifies a single trace using a 16-byte array.
///
/// [W3C TraceContext: trace-id](https://www.w3.org/TR/trace-context-1/#trace-id)
public struct OTelTraceID {
    private let _bytes: Bytes

    /// Create an ``OTelTraceID`` from the given bytes.
    ///
    /// - Parameter bytes: A 16-byte array representing the trace ID.
    public init(bytes: Bytes) {
        _bytes = bytes
    }

    /// 16-byte array representation of the trace ID.
    public var bytes: [UInt8] {
        withUnsafeBytes(of: _bytes, Array.init)
    }

    /// A 16-byte array.
    public typealias Bytes = (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )
}

extension OTelTraceID: CustomStringConvertible {
    /// A hex string representation of the trace ID.
    public var description: String {
        String(decoding: hexBytes, as: UTF8.self)
    }

    /// A 32 character long UTF-8 hex byte array representation of the trace ID.
    public var hexBytes: [UInt8] {
        var asciiBytes: (UInt64, UInt64, UInt64, UInt64) = (0, 0, 0, 0)
        return withUnsafeMutableBytes(of: &asciiBytes) { ptr in
            ptr[0] = Hex.lookup[Int(_bytes.0 >> 4)]
            ptr[1] = Hex.lookup[Int(_bytes.0 & 0x0F)]
            ptr[2] = Hex.lookup[Int(_bytes.1 >> 4)]
            ptr[3] = Hex.lookup[Int(_bytes.1 & 0x0F)]
            ptr[4] = Hex.lookup[Int(_bytes.2 >> 4)]
            ptr[5] = Hex.lookup[Int(_bytes.2 & 0x0F)]
            ptr[6] = Hex.lookup[Int(_bytes.3 >> 4)]
            ptr[7] = Hex.lookup[Int(_bytes.3 & 0x0F)]
            ptr[8] = Hex.lookup[Int(_bytes.4 >> 4)]
            ptr[9] = Hex.lookup[Int(_bytes.4 & 0x0F)]
            ptr[10] = Hex.lookup[Int(_bytes.5 >> 4)]
            ptr[11] = Hex.lookup[Int(_bytes.5 & 0x0F)]
            ptr[12] = Hex.lookup[Int(_bytes.6 >> 4)]
            ptr[13] = Hex.lookup[Int(_bytes.6 & 0x0F)]
            ptr[14] = Hex.lookup[Int(_bytes.7 >> 4)]
            ptr[15] = Hex.lookup[Int(_bytes.7 & 0x0F)]
            ptr[16] = Hex.lookup[Int(_bytes.8 >> 4)]
            ptr[17] = Hex.lookup[Int(_bytes.8 & 0x0F)]
            ptr[18] = Hex.lookup[Int(_bytes.9 >> 4)]
            ptr[19] = Hex.lookup[Int(_bytes.9 & 0x0F)]
            ptr[20] = Hex.lookup[Int(_bytes.10 >> 4)]
            ptr[21] = Hex.lookup[Int(_bytes.10 & 0x0F)]
            ptr[22] = Hex.lookup[Int(_bytes.11 >> 4)]
            ptr[23] = Hex.lookup[Int(_bytes.11 & 0x0F)]
            ptr[24] = Hex.lookup[Int(_bytes.12 >> 4)]
            ptr[25] = Hex.lookup[Int(_bytes.12 & 0x0F)]
            ptr[26] = Hex.lookup[Int(_bytes.13 >> 4)]
            ptr[27] = Hex.lookup[Int(_bytes.13 & 0x0F)]
            ptr[28] = Hex.lookup[Int(_bytes.14 >> 4)]
            ptr[29] = Hex.lookup[Int(_bytes.14 & 0x0F)]
            ptr[30] = Hex.lookup[Int(_bytes.15 >> 4)]
            ptr[31] = Hex.lookup[Int(_bytes.15 & 0x0F)]
            return Array(ptr)
        }
    }
}

extension OTelTraceID: Equatable {
    public static func == (lhs: OTelTraceID, rhs: OTelTraceID) -> Bool {
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

extension OTelTraceID: Hashable {
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

extension OTelTraceID: Sendable {}
