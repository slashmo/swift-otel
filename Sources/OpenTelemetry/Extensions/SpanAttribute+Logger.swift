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

import Logging
import Tracing

extension SpanAttributes {
    var metadata: Logger.Metadata {
        var metadata = Logger.Metadata()
        forEach { key, value in
            metadata[key] = value.metadataValue
        }
        return metadata
    }
}

extension SpanAttribute {
    fileprivate var metadataValue: Logger.MetadataValue {
        switch self {
        case .string(let value):
            return .string(value)
        case .stringArray(let value):
            return .array(value.map { SpanAttribute.string($0).metadataValue })
        case .int32Array(let value):
            return .array(value.map { SpanAttribute.int32($0).metadataValue })
        case .int64Array(let value):
            return .array(value.map { SpanAttribute.int64($0).metadataValue })
        case .boolArray(let value):
            return .array(value.map { SpanAttribute.bool($0).metadataValue })
        case .stringConvertibleArray(let value):
            return .array(value.map { SpanAttribute.stringConvertible($0).metadataValue })
        case .stringConvertible(let value),
             .doubleArray(let value as CustomStringConvertible & Sendable),
             .bool(let value as CustomStringConvertible & Sendable),
             .double(let value as CustomStringConvertible & Sendable),
             .int32(let value as CustomStringConvertible & Sendable),
             .int64(let value as CustomStringConvertible & Sendable):
            return .stringConvertible(value)
        default:
            fatalError("not supported")
        }
    }
}
