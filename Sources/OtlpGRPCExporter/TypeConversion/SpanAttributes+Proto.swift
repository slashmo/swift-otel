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

import Tracing

extension Opentelemetry_Proto_Common_V1_AnyValue {
    init(_ attribute: SpanAttribute) {
        self = .with { value in
            switch attribute {
            case .string(let string):
                value.stringValue = string
            case .stringArray(let stringArray):
                value.arrayValue = .init(stringArray, transform: SpanAttribute.string)
            case .stringConvertible(let stringConvertible):
                value.stringValue = String(describing: stringConvertible)
            case .stringConvertibleArray(let stringConvertibleArray):
                value.arrayValue = .init(stringConvertibleArray, transform: SpanAttribute.stringConvertible)
            case .int(let int):
                value.intValue = int
            case .intArray(let intArray):
                value.arrayValue = .init(intArray, transform: SpanAttribute.int)
            case .double(let double):
                value.doubleValue = double
            case .doubleArray(let doubleArray):
                value.arrayValue = .init(doubleArray, transform: SpanAttribute.double)
            case .bool(let bool):
                value.boolValue = bool
            case .boolArray(let boolArray):
                value.arrayValue = .init(boolArray, transform: SpanAttribute.bool)
            }
        }
    }
}

extension Opentelemetry_Proto_Common_V1_ArrayValue {
    init<T>(_ array: [T], transform: (T) -> SpanAttribute) {
        self = .with { a in
            a.values = array.map { .init(transform($0)) }
        }
    }
}

extension Array where Element == Opentelemetry_Proto_Common_V1_KeyValue {
    init(_ attributes: SpanAttributes) {
        self.init()
        attributes.forEach { key, attribute in
            self.append(Opentelemetry_Proto_Common_V1_KeyValue.with { keyValue in
                keyValue.key = key
                keyValue.value = .init(attribute)
            })
        }
    }
}
