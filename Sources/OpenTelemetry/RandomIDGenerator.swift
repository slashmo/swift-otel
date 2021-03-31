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

extension OTel {
    /// Generates random trace and span ids using a `RandomNumberGenerator`.
    public struct RandomIDGenerator: OTelIDGenerator {
        private var randomNumberGenerator: RandomNumberGenerator

        /// Initialize a random `IDGenerator` backed by the given `RandomNumberGenerator`.
        ///
        /// - Parameter randomNumberGenerator: The `RandomNumberGenerator` to use, defaults to a `SystemRandomNumberGenerator`.
        public init(randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
            self.randomNumberGenerator = randomNumberGenerator
        }

        public mutating func generateTraceID() -> TraceID {
            var bytes: TraceID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            withUnsafeMutableBytes(of: &bytes) { ptr in
                ptr.storeBytes(of: randomNumberGenerator.next().bigEndian, as: UInt64.self)
                ptr.storeBytes(of: randomNumberGenerator.next().bigEndian, toByteOffset: 8, as: UInt64.self)
            }
            return TraceID(bytes: bytes)
        }

        public mutating func generateSpanID() -> SpanID {
            var bytes: SpanID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0)
            withUnsafeMutableBytes(of: &bytes) { ptr in
                ptr.storeBytes(of: randomNumberGenerator.next().bigEndian, as: UInt64.self)
            }
            return SpanID(bytes: bytes)
        }
    }
}
