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
import NIO
import Tracing

extension OTel {
    /// Configures how resource attributes may be detected.
    public enum ResourceDetection {
        /// Automatically detect resource attributes based on the process, environment, and any given additional detectors.
        case automatic(additionalDetectors: [ResourceDetector])
        /// Uses the given resource as the single source of truth.
        case manual(Resource)
        /// Does not detect any attributes, i.e. results in an empty `OTel.Resource`.
        case none
    }
}

extension OTel.ResourceDetection {
    func detectAttributes(
        for resource: OTel.Resource,
        on eventLoopGroup: EventLoopGroup) -> EventLoopFuture<OTel.Resource> {
        let promise = eventLoopGroup.next().makePromise(of: OTel.Resource.self)
        let sdkResource: () -> OTel.Resource = {
            OTel.Resource(attributes: [
                "telemetry.sdk.name": "opentelemetry",
                "telemetry.sdk.language": "swift",
                "telemetry.sdk.version": .string(OTel.versionString),
            ])
        }
        switch self {
        case .automatic(let additionalDetectors):
            let detectors = [
                OTel.EnvironmentResourceDetector(eventLoopGroup: eventLoopGroup),
                OTel.ProcessResourceDetector(eventLoopGroup: eventLoopGroup),
            ] + additionalDetectors

            promise.completeWith(.reduce(
                sdkResource(),
                detectors.map { $0.detect() },
                on: eventLoopGroup.next()) { $0.merging($1) })
        case .manual(let resource):
            promise.completeWith(.success(sdkResource().merging(resource)))
        case .none:
            promise.completeWith(.success(OTel.Resource()))
        }
        return promise.futureResult
    }
}
