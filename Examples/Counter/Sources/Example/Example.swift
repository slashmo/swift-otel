//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIO
import OTel
import OTLPGRPC
import ServiceLifecycle
import Tracing

@main
enum Example {
    static func main() async throws {
        let environment = OTelEnvironment.detected()
        let resourceDetection = OTelResourceDetection(detectors: [
            OTelProcessResourceDetector(),
            OTelEnvironmentResourceDetector(environment: environment),
            .manual(OTelResource(attributes: ["service.name": "counter"])),
        ])
        let resource = await resourceDetection.resource(environment: environment, logLevel: .trace)

        /*
         Bootstrap the logging system to use the OTel metadata provider.
         This will automatically include trace and span IDs in log statements
         from your app and its dependencies.
         */
        LoggingSystem.bootstrap({ label, _ in
            var handler = StreamLogHandler.standardOutput(label: label)
            // We set the lowest possible minimum log level to see all log statements.
            handler.logLevel = .trace
            return handler
        }, metadataProvider: .otel)
        let logger = Logger(label: "example")

        /*
         Here we create an OTel span exporter that sends spans via gRPC to an OTel collector.
         */
        let exporter = try OTLPGRPCSpanExporter(configuration: .init(environment: environment))

        /*
         This exporter is passed to a batch span processor.
         The processor receives ended spans from the tracer, batches them up, and finally forwards them to the exporter.
         */
        let processor = OTelBatchSpanProcessor(exporter: exporter, configuration: .init(environment: environment))

        /*
         We need to await tracer initialization since the tracer needs
         some time to detect attributes about the resource being traced.
         */
        let tracer = OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelConstantSampler(isOn: true),
            propagator: OTelW3CPropagator(),
            processor: processor,
            environment: environment,
            resource: resource
        )

        /*
         Once we have a tracer, we bootstrap the instrumentation system to use it.
         This configures your application code and any of your dependencies to use the OTel tracer.
         */
        InstrumentationSystem.bootstrap(tracer)

        let service = Counter()

        /*
         Finally, OTel uses swift-server/swift-service-lifecycle to control the tracers lifetime.
         Usually, you'd want to have the tracer be one of the first services and definitely before
         your app services since this will allow to still export spans during graceful shutdown of
         your app.
         */
        let serviceGroup = ServiceGroup(
            services: [tracer, service],
            gracefulShutdownSignals: [.sigint],
            logger: logger
        )
        try await serviceGroup.run()
    }
}

struct Counter: Service, CustomStringConvertible {
    let description = "Example"

    private let stream: AsyncStream<Int>
    private let continuation: AsyncStream<Int>.Continuation

    private let logger = Logger(label: "Counter")

    init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    func run() async {
        continuation.yield(0)

        for await value in stream.cancelOnGracefulShutdown() {
            let delay = Duration.seconds(.random(in: 0 ..< 1))

            do {
                try await withSpan("count") { span in
                    if value % 10 == 0 {
                        logger.error("Failed to count up, skipping value.", metadata: ["value": "\(value)"])
                        span.recordError(CounterError.failedIncrementing(value: value))
                        span.setStatus(.init(code: .error))
                        continuation.yield(value + 1)
                    } else {
                        span.attributes["value"] = value
                        logger.info("Counted up.", metadata: ["count": "\(value)"])
                        try await Task.sleep(for: delay)
                        continuation.yield(value + 1)
                    }
                }
            } catch {
                return
            }
        }
    }
}

enum CounterError: Error {
    case failedIncrementing(value: Int)
}
