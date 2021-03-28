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
        case .intArray(let value):
            return .array(value.map { SpanAttribute.int($0).metadataValue })
        case .boolArray(let value):
            return .array(value.map { SpanAttribute.bool($0).metadataValue })
        case .stringConvertibleArray(let value):
            return .array(value.map { SpanAttribute.stringConvertible($0).metadataValue })
        case .stringConvertible(let value),
             .doubleArray(let value as CustomStringConvertible),
             .bool(let value as CustomStringConvertible),
             .double(let value as CustomStringConvertible),
             .int(let value as CustomStringConvertible):
            return .stringConvertible(value)
        }
    }
}
