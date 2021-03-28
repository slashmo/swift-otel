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

import class Foundation.ProcessInfo
import NIO
import Tracing

extension OTel {
    struct EnvironmentResourceDetector: ResourceDetector {
        private let eventLoopGroup: EventLoopGroup
        private let environment: [String: String]

        init(eventLoopGroup: EventLoopGroup, environment: [String: String] = ProcessInfo.processInfo.environment) {
            self.eventLoopGroup = eventLoopGroup
            self.environment = environment
        }

        func detect() -> EventLoopFuture<Resource> {
            guard let attributesString = environment["OTEL_RESOURCE_ATTRIBUTES"] else {
                return eventLoopGroup.next().makeSucceededFuture(Resource())
            }

            var attributes: SpanAttributes = [:]
            let keyValuePairs = attributesString.components(separatedBy: ",")

            for keyValuePair in keyValuePairs {
                let parts = keyValuePair.components(separatedBy: "=")
                guard parts.count == 2 else {
                    return eventLoopGroup.next().makeFailedFuture(Error.invalidKeyValuePair(keyValuePair))
                }
                attributes[parts[0]] = parts[1]
            }

            return eventLoopGroup.next().makeSucceededFuture(Resource(attributes: attributes))
        }
    }
}

extension OTel.EnvironmentResourceDetector {
    public enum Error: Swift.Error {
        case invalidKeyValuePair(String)
    }
}
