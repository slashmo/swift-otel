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

import AsyncAlgorithms
import Logging
import Tracing

/// Configures how to detect attributes describing the resource being instrumented.
public enum OTelResourceDetection: Sendable {
    /// Automatically detect resource attributes based on the process, the `OTEL_RESOURCE_ATTRIBUTES` environment variable,
    /// and any given additional detectors.
    ///
    /// - Parameter additionalDetectors: Detectors that run after the built-in detectors, overriding any duplicate keys detected by those.
    case automatic(additionalDetectors: [any OTelResourceDetector] = [])

    /// Use the given resource directly.
    case manual(OTelResource)

    /// Disable resource detection.
    case disabled

    @_spi(Testing)
    public func resource(
        processDetector: OTelProcessResourceDetector = OTelProcessResourceDetector(),
        environmentDetector: OTelEnvironmentResourceDetector,
        logger: Logger
    ) async -> OTelResource {
        let sdkResource: () -> OTelResource = {
            OTelResource(attributes: [
                "telemetry.sdk.name": "opentelemetry",
                "telemetry.sdk.language": "swift",
                "telemetry.sdk.version": "\(OTelLibrary.version)",
            ])
        }

        switch self {
        case .automatic(let additionalDetectors):
            let detectors = [processDetector, environmentDetector] + additionalDetectors

            return await withTaskGroup(of: (Int, OTelResource).self, returning: OTelResource.self) { group in
                logger.trace("Running resource detectors.", metadata: [
                    "detectors": .array(detectors.map { .string("\($0)") }),
                ])

                for (index, detector) in detectors.enumerated() {
                    group.addTask {
                        do {
                            let resource = try await detector.resource()
                            logger.trace("Detected resource.", metadata: ["detector": "\(detector)"])
                            return (index, resource)
                        } catch {
                            logger.error("Failed to detect resource.", metadata: [
                                "detector": "\(detector)",
                                "error_type": "\(type(of: error))",
                                "error_description": "\(error)",
                            ])
                            return (index, OTelResource())
                        }
                    }
                }

                let resource = await group
                    .reduce(into: [Int: OTelResource]()) { $0[$1.0] = $1.1 }
                    .lazy
                    .sorted { $0.key < $1.key }
                    .reduce(OTelResource()) { $0.merging($1.value) }

                return sdkResource().merging(resource)
            }
        case .manual(let resource):
            return sdkResource().merging(resource)
        case .disabled:
            return OTelResource()
        }
    }
}
