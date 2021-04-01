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

import Instrumentation

extension OTel {
    /// A propagator which operates on HTTP headers using the [W3C TraceContext](https://www.w3.org/TR/2020/REC-trace-context-1-20200206/).
    public struct W3CPropagator: OTelPropagator {
        private static let traceParentHeaderName = "traceparent"
        private static let traceStateHeaderName = "tracestate"
        private static let dash = UInt8(ascii: "-")

        /// Initialize a `W3CPropagator`.
        public init() {}

        public func extractSpanContext<Carrier, Extract>(
            from carrier: Carrier,
            using extractor: Extract
        ) throws -> OTel.SpanContext? where Extract: Extractor, Carrier == Extract.Carrier {
            guard let traceParentString = extractor.extract(key: Self.traceParentHeaderName, from: carrier) else {
                return nil
            }

            var spanContext = try extractSpanContext(fromHeader: traceParentString)
            spanContext?.traceState = try extractor
                .extract(key: Self.traceStateHeaderName, from: carrier)
                .flatMap(extractTraceState(fromHeader:))

            return spanContext
        }

        public func inject<Carrier, Inject>(
            _ spanContext: OTel.SpanContext,
            into carrier: inout Carrier,
            using injector: Inject
        ) where Inject: Injector, Carrier == Inject.Carrier {
            let traceFlagsUnpadded = String(spanContext.traceFlags.rawValue, radix: 16, uppercase: false)
            let traceFlags = traceFlagsUnpadded.count == 1 ? "0\(traceFlagsUnpadded)" : traceFlagsUnpadded
            let traceParent = "00-\(spanContext.traceID)-\(spanContext.spanID)-\(traceFlags)"
            injector.inject(traceParent, forKey: Self.traceParentHeaderName, into: &carrier)

            if let traceState = spanContext.traceState {
                let traceStateString = String(describing: traceState)
                injector.inject(traceStateString, forKey: Self.traceStateHeaderName, into: &carrier)
            }
        }

        private func extractSpanContext(fromHeader header: String) throws -> OTel.SpanContext? {
            try header.utf8.withContiguousStorageIfAvailable { traceParent -> OTel.SpanContext in
                guard traceParent.count == 55 else {
                    throw TraceParentParsingError(value: header, reason: .invalidLength(traceParent.count))
                }
                guard traceParent[0] == UInt8(ascii: "0"), traceParent[1] == UInt8(ascii: "0") else {
                    throw TraceParentParsingError(
                        value: header,
                        reason: .unsupportedVersion(String(decoding: traceParent[0 ... 1], as: UTF8.self))
                    )
                }
                guard traceParent[2] == Self.dash, traceParent[35] == Self.dash, traceParent[52] == Self.dash else {
                    throw TraceParentParsingError(value: header, reason: .invalidDelimiters)
                }

                var traceIDBytes = OTel.TraceID.Bytes(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                withUnsafeMutableBytes(of: &traceIDBytes) { ptr in
                    OTel.Hex.convert(traceParent[3 ..< 35], toBytes: ptr)
                }

                var spanIDBytes = OTel.SpanID.Bytes(0, 0, 0, 0, 0, 0, 0, 0)
                withUnsafeMutableBytes(of: &spanIDBytes) { ptr in
                    OTel.Hex.convert(traceParent[36 ..< 52], toBytes: ptr)
                }

                var traceFlagsRawValue: UInt8 = 0
                withUnsafeMutableBytes(of: &traceFlagsRawValue) { ptr in
                    OTel.Hex.convert(traceParent[53 ..< 55], toBytes: ptr)
                }
                let traceFlags = OTel.TraceFlags(rawValue: traceFlagsRawValue)

                return OTel.SpanContext(
                    traceID: OTel.TraceID(bytes: traceIDBytes),
                    spanID: OTel.SpanID(bytes: spanIDBytes),
                    traceFlags: traceFlags,
                    isRemote: true
                )
            }
        }

        private func extractTraceState(fromHeader header: String) throws -> OTel.TraceState? {
            guard !header.isEmpty else { return nil }

            let keyValuePairs = header.split(separator: ",")
            var storage = OTel.TraceState.Storage()

            for var rest in keyValuePairs {
                var vendor = ""

                while vendor.count < 256, !rest.hasPrefix("="), !rest.isEmpty {
                    let next = rest.removeFirst()
                    switch next {
                    case "a" ... "z", "0" ... "9", "_", "-", "*", "/":
                        vendor.append(next)
                    case "@":
                        vendor.append(next)
                    default:
                        throw TraceStateParsingError(value: header, reason: .invalidCharacter(next))
                    }
                }

                guard !vendor.isEmpty, rest.hasPrefix("=") else {
                    throw TraceStateParsingError(value: header, reason: .missingValue(vendor: vendor))
                }
                rest.removeFirst()

                var value = [Character]()

                while value.count < 256, !rest.isEmpty {
                    let next = rest.removeFirst()
                    guard Character.printableAsciiRange.contains(next), next != "=" else {
                        throw TraceStateParsingError(value: header, reason: .invalidCharacter(next))
                    }
                    value.append(next)
                }

                storage.append((vendor: vendor, value: String(value)))
            }

            return OTel.TraceState(storage)
        }
    }
}

extension OTel.W3CPropagator {
    /// An error that might occur during the parsing of the traceparent header.
    public struct TraceParentParsingError: Error, Equatable {
        /// The header value that caused the failure.
        public let value: String

        /// A reason explaining why parsing failed.
        public let reason: Reason
    }

    /// An error that might occur during the parsing of the traceparent header.
    public struct TraceStateParsingError: Error, Equatable {
        /// The header value that caused the failure.
        public let value: String

        /// A reason explaining why parsing failed.
        public let reason: Reason
    }
}

extension OTel.W3CPropagator.TraceParentParsingError {
    /// A reason explaining why trace parent parsing failed.
    public enum Reason: Equatable {
        /// The header has an invalid length.
        case invalidLength(Int)

        /// The header uses an unsupported version.
        case unsupportedVersion(String)

        /// The header does not use the correct delimiters.
        case invalidDelimiters
    }
}

extension OTel.W3CPropagator.TraceStateParsingError {
    /// A reason explaining why trace state parsing failed.
    public enum Reason: Equatable {
        /// The header misses a value for the given vendor.
        case missingValue(vendor: String)

        /// The header contains the given invalid character.
        case invalidCharacter(Character)
    }
}

extension Character {
    fileprivate static let printableAsciiRange: ClosedRange<Character> = " " ... "~"
}
