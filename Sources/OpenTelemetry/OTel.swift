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
import Metrics

/// The main entry point to using OpenTelemetry.
public final class OTel {
    /// The current `semver` version of the library.
    public static let versionString = "0.3.0"

    private let eventLoopGroup: EventLoopGroup
    private let resourceDetection: ResourceDetection
    private let idGenerator: OTelIDGenerator
    private let sampler: OTelSampler
    private let traceProcessor: OTelSpanProcessor
    private let logProcessor: OTelLogProcessor
    private let propagator: OTelPropagator
    private let logger: Logger

    // internal get for testing
    private(set) var resource: Resource

    /// Initialize `OTel` with the given configuration. Don't forget to also call `start` early on in your application.
    ///
    /// - Parameters:
    ///   - serviceName: The name of the service being traced, e.g. "checkout".
    ///   - eventLoopGroup: The `EventLoopGroup` to run on.
    ///   - resourceDetection: Configures how resource attribution may be detected, defaults to `.automatic`.
    ///   - sampler: Configures the sampler to be used, defaults to an *always on* sampler as the root of a parent-based sampler.
    ///   - processor: Configures the span processor to be used for ended spans, defaults to a no-op processor.
    ///   - propagator: Configures the propagator to be used, defaults to a `W3CPropagator`.
    ///   - logger: The Logger used by OTel and its sub-components.
    public init(
        serviceName: String,
        eventLoopGroup: EventLoopGroup,
        resourceDetection: ResourceDetection = .automatic(additionalDetectors: []),
        idGenerator: OTelIDGenerator = RandomIDGenerator(),
        sampler: OTelSampler = ParentBasedSampler(rootSampler: ConstantSampler(isOn: true)),
        processor: OTelSpanProcessor? = nil,
        logProcessor: OTelLogProcessor? = nil,
        propagator: OTelPropagator = W3CPropagator(),
        logger: Logger = Logger(label: "OTel")
    ) {
        resource = Resource(attributes: ["service.name": .string(serviceName)])
        self.eventLoopGroup = eventLoopGroup
        self.resourceDetection = resourceDetection
        self.idGenerator = idGenerator
        self.sampler = sampler
        self.traceProcessor = processor ?? NoOpSpanProcessor(eventLoopGroup: eventLoopGroup)
        self.logProcessor = logProcessor ?? NoOpLogProcessor(eventLoopGroup: eventLoopGroup)
        self.propagator = propagator
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
                    self?.logger.trace("Detected resource", metadata: resource.attributes.metadata)
                    self?.resource = resource
                case .failure(let error):
                    self?.logger.debug("Failed to detect resource", metadata: [
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
        Tracer(
            resource: resource,
            idGenerator: idGenerator,
            sampler: sampler,
            processor: traceProcessor,
            propagator: propagator,
            logger: logger
        )
    }
    
//    public func metricsFactory() -> Metrics.MetricsFactory {
//        MetricsFactory(
//            resource: resource,
//            idGenerator: idGenerator,
//            sampler: sampler,
//            processor: processor,
//            propagator: propagator,
//            logger: logger
//        )
//    }
    
    public func logHandler(
        logLevel: Logger.Level,
        metadata: Logger.Metadata = .init()
    ) -> Logging.LogHandler {
        LogHandler(
            resource: resource,
            logLevel: logLevel,
            metadata: metadata,
            processor: logProcessor
        )
    }

    /// Shutdown `OTel`.
    ///
    /// - Returns: A future that completes once `OTel` and its sub-components was shutdown.
    public func shutdown() -> EventLoopFuture<Void> {
        traceProcessor.shutdownGracefully()
    }
}
