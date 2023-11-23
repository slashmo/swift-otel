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

import Tracing

@_spi(Testing)
public struct OTelEnvironmentResourceDetector: OTelResourceDetector {
    public let description = "environment"

    private let environment: OTelEnvironment

    public init(environment: OTelEnvironment) {
        self.environment = environment
    }

    public func resource() async throws -> OTelResource {
        let environmentKey = "OTEL_RESOURCE_ATTRIBUTES"
        guard let environmentValue = environment.values[environmentKey] else { return OTelResource() }

        let attributes: SpanAttributes = try {
            var attributes = SpanAttributes()
            let keyValuePairs = environmentValue.split(separator: ",")

            for keyValuePair in keyValuePairs {
                let parts = keyValuePair.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else {
                    throw Error.invalidKeyValuePair(parts)
                }
                attributes["\(parts[0])"] = "\(parts[1])"
            }

            return attributes
        }()

        return OTelResource(attributes: attributes)
    }

    public enum Error: Swift.Error, Equatable {
        case invalidKeyValuePair([Substring])
    }
}
