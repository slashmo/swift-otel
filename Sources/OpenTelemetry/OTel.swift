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

/// The main entry point to using OpenTelemetry.
public final class OTel {
    /// The current `semver` version of the library.
    public static let versionString = "0.0.1-alpha"

    private let eventLoopGroup: EventLoopGroup
    private let resourceDetection: ResourceDetection
    private let idGenerator: IDGenerator
    private let logger: Logger

    // internal get for testing
    private(set) var resource: Resource

    /// Initialize `OTel` with the given configuration. Don't forget to also call `start` early on in your application.
    ///
    /// - Parameters:
    ///   - serviceName: The name of the service being traced, e.g. "checkout".
    ///   - eventLoopGroup: The `EventLoopGroup` to run on.
    ///   - resourceDetection: Configures how resource attribution may be detected, defaults to `.automatic`.
    ///   - logger: The Logger used by OTel and its sub-components.
    public init(
        serviceName: String,
        eventLoopGroup: EventLoopGroup,
        resourceDetection: ResourceDetection = .automatic(additionalDetectors: []),
        idGenerator: IDGenerator = RandomIDGenerator(),
        logger: Logger = Logger(label: "OTel")
    ) {
        resource = Resource(attributes: ["service.name": .string(serviceName)])
        self.eventLoopGroup = eventLoopGroup
        self.resourceDetection = resourceDetection
        self.idGenerator = idGenerator
        self.logger = logger
    }

    /// Start `OTel` to detect information about the resource your application is running on.
    ///
    /// - Returns: A future that completes once `OTel` and its sub-components was started.
    public func start() -> EventLoopFuture<Void> {
        resourceDetection
            .detectAttributes(for: resource, on: eventLoopGroup)
            .always { [weak self] result in
                switch result {
                case .success(let resource):
                    self?.logger.debug("Detected resource", metadata: resource.attributes.metadata)
                    self?.resource = resource
                case .failure(let error):
                    self?.logger.warning("Failed to detect resource", metadata: [
                        "error": .string(String(describing: error)),
                    ])
                }
            }
            .map { _ in () }
    }

    /// Retrieve a configured `Tracer`.
    ///
    /// Instead of using the returned instance directly to trace your application,
    /// use it to bootstrap the instrumentation system:
    ///
    ///     InstrumentationSystem.bootstrap(otel.tracer())
    ///     // somewhere else in your application
    ///     InstrumentationSystem.tracer.startSpan(...)
    ///
    /// - Returns: An OTel Tracer conforming to the [`Tracer`](https://github.com/apple/swift-distributed-tracing/blob/main/Sources/Tracing/Tracer.swift) protocol.
    public func tracer() -> Tracing.Tracer {
        Tracer(idGenerator: idGenerator)
    }

    /// Shutdown `OTel`.
    ///
    /// - Returns: A future that completes once `OTel` and its sub-components was shutdown.
    public func shutdown() -> EventLoopFuture<Void> {
        eventLoopGroup.next().makeSucceededVoidFuture()
    }
}
