//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging

extension Opentelemetry_Proto_Common_V1_AnyValue {
    init(_ metadataValue: Logger.MetadataValue) {
        self = .with { value in
            switch metadataValue {
            case .string(let string):
                value.stringValue = string
            case .stringConvertible(let stringConvertible):
                value.stringValue = String(describing: stringConvertible)
            case .array(let values):
                value.arrayValue = .with { arrayValue in
                    arrayValue.values = values.map(Opentelemetry_Proto_Common_V1_AnyValue.init)
                }
            case .dictionary(let metadata):
                value.stringValue = "\(metadata)"
            }
        }
    }
}

extension Array where Element == Opentelemetry_Proto_Common_V1_KeyValue {
    init(_ metadata: Logger.Metadata) {
        self.init()
        for (key, value) in metadata {
            append(Opentelemetry_Proto_Common_V1_KeyValue.with { keyValue in
                keyValue.key = key
                keyValue.value = .init(value)
            })
        }
    }
}
