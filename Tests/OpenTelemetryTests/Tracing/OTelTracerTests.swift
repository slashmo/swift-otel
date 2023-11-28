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

import Logging
@testable @_spi(Testing) import OpenTelemetry
import OTelTesting
import ServiceContextModule
import ServiceLifecycle
import XCTest

final class OTelTracerTests: XCTestCase {
    override func setUp() async throws {
        LoggingSystem.bootstrapInternal(logLevel: .trace)
    }

    // MARK: - Tracer

    func test_startSpan_withoutParentSpanContext_generatesNewTraceID() async throws {
        let idGenerator = OTelConstantIDGenerator(traceID: .oneToSixteen, spanID: .oneToEight)
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let processor = OTelNoOpSpanProcessor()

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:]
        )

        let span = tracer.startSpan("test")
        let spanContext = try XCTUnwrap(span.context.spanContext)
        XCTAssertEqual(
            spanContext,
            OTelSpanContext(
                traceID: .oneToSixteen,
                spanID: .oneToEight,
                parentSpanID: nil,
                traceFlags: .sampled,
                traceState: nil,
                isRemote: false
            )
        )
    }

    func test_startSpan_withParentSpanContext_reusesTraceID() async throws {
        let idGenerator = OTelConstantIDGenerator(traceID: .oneToSixteen, spanID: .oneToEight)
        let randomIDGenerator = OTelRandomIDGenerator()
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let processor = OTelNoOpSpanProcessor()

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:]
        )

        let traceID = randomIDGenerator.nextTraceID()
        let parentSpanID = randomIDGenerator.nextSpanID()
        let traceState = OTelTraceState(items: [OTelTraceState.Item(vendor: "foo", value: "bar")])

        var parentContext = ServiceContext.topLevel
        let parentSpanContext = OTelSpanContext(
            traceID: traceID,
            spanID: parentSpanID,
            parentSpanID: nil,
            traceFlags: .sampled,
            traceState: traceState,
            isRemote: true
        )
        parentContext.spanContext = parentSpanContext

        let span = tracer.startSpan("test", context: parentContext)
        let spanContext = try XCTUnwrap(span.context.spanContext)
        XCTAssertEqual(
            spanContext,
            OTelSpanContext(
                traceID: traceID,
                spanID: .oneToEight,
                parentSpanID: parentSpanID,
                traceFlags: .sampled,
                traceState: traceState,
                isRemote: false
            )
        )
    }

    func test_startSpan_whenSamplerDrops_doesNotSetSampledFlag() async throws {
        let idGenerator = OTelConstantIDGenerator(traceID: .oneToSixteen, spanID: .oneToEight)
        let sampler = OTelConstantSampler(decision: .drop)
        let propagator = OTelW3CPropagator()
        let processor = OTelNoOpSpanProcessor()

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:]
        )

        let span = tracer.startSpan("test")
        let spanContext = try XCTUnwrap(span.context.spanContext)
        XCTAssertEqual(
            spanContext,
            OTelSpanContext(
                traceID: .oneToSixteen,
                spanID: .oneToEight,
                parentSpanID: nil,
                traceFlags: [],
                traceState: nil,
                isRemote: false
            )
        )
    }

    func test_startSpan_whenSamplerRecordsWithoutSampling_doesNotSetSampledFlag() async throws {
        let idGenerator = OTelConstantIDGenerator(traceID: .oneToSixteen, spanID: .oneToEight)
        let sampler = OTelConstantSampler(decision: .record)
        let propagator = OTelW3CPropagator()
        let processor = OTelNoOpSpanProcessor()

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:]
        )

        let span = tracer.startSpan("test")
        let spanContext = try XCTUnwrap(span.context.spanContext)
        XCTAssertEqual(
            spanContext,
            OTelSpanContext(
                traceID: .oneToSixteen,
                spanID: .oneToEight,
                parentSpanID: nil,
                traceFlags: [],
                traceState: nil,
                isRemote: false
            )
        )
    }

    func test_startSpan_whenSamplerDrops_usesNoOpSpan() async throws {
        let idGenerator = OTelConstantIDGenerator(traceID: .oneToSixteen, spanID: .oneToEight)
        let sampler = OTelConstantSampler(decision: .drop)
        let propagator = OTelW3CPropagator()
        let processor = OTelNoOpSpanProcessor()

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:]
        )

        let span = tracer.startSpan("test")
        XCTAssertFalse(span.isRecording)
        XCTAssertEqual(span.operationName, "noop")
    }

    func test_startSpan_onSpanEnd_whenSpanIsSampled_forwardsSpanToProcessor() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let exporter = OTelStreamingSpanExporter()
        var batches = await exporter.batches.makeAsyncIterator()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:],
            resourceDetection: .manual(OTelResource(attributes: ["service.name": "test"]))
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)

        Task {
            try await serviceGroup.run()
        }

        let span = tracer.startSpan("1")
        span.end()

        let batch1 = await batches.next()
        let finishedSpan = try XCTUnwrap(batch1?.first)
        XCTAssertEqual(finishedSpan.operationName, "1")
        XCTAssertEqual(finishedSpan.resource.attributes["service.name"]?.toSpanAttribute(), "test")

        await serviceGroup.triggerGracefulShutdown()
    }

    func test_startSpan_onSpanEnd_whenSpanWasDropped_doesNotForwardSpanToProcessor() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let sampler = OTelInlineSampler { operationName, _, _, _, _, _ in
            operationName == "1" ? .init(decision: .drop) : .init(decision: .recordAndSample)
        }
        let propagator = OTelW3CPropagator()
        let exporter = OTelStreamingSpanExporter()
        var batches = await exporter.batches.makeAsyncIterator()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:]
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)

        Task {
            try await serviceGroup.run()
        }

        let span1 = tracer.startSpan("1")
        span1.end()

        let span2 = tracer.startSpan("2")
        span2.end()

        let batch1 = await batches.next()
        XCTAssertEqual(try XCTUnwrap(batch1).map(\.operationName), ["2"])

        await serviceGroup.triggerGracefulShutdown()
    }

    func test_startSpan_onSpanEnd_whenServiceNameEnvironmentVariableIsSet_usesServiceName() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let exporter = OTelStreamingSpanExporter()
        var batches = await exporter.batches.makeAsyncIterator()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        struct ManualDetector: OTelResourceDetector {
            let description = "manual"

            func resource() async throws -> OTelResource { OTelResource(attributes: ["service.name": "manual"]) }
        }

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [
                "OTEL_SERVICE_NAME": "environment",
                "OTEL_RESOURCE_ATTRIBUTES": "service.name=environment_resource_attributes",
            ],
            resourceDetection: .automatic(additionalDetectors: [ManualDetector()])
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)

        Task {
            try await serviceGroup.run()
        }

        let span = tracer.startSpan("1")
        span.end()

        let batch1 = await batches.next()
        let finishedSpan = try XCTUnwrap(batch1?.first)
        XCTAssertEqual(finishedSpan.resource.attributes["service.name"]?.toSpanAttribute(), "environment")

        await serviceGroup.triggerGracefulShutdown()
    }

    func test_startSpan_onSpanEnd_whenServiceNameAttributeIsSet_usesServiceName() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let exporter = OTelStreamingSpanExporter()
        var batches = await exporter.batches.makeAsyncIterator()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:],
            resourceDetection: .manual(OTelResource(attributes: ["service.name": "manual"]))
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)

        Task {
            try await serviceGroup.run()
        }

        let span = tracer.startSpan("1")
        span.end()

        let batch1 = await batches.next()
        let finishedSpan = try XCTUnwrap(batch1?.first)
        XCTAssertEqual(finishedSpan.resource.attributes["service.name"]?.toSpanAttribute(), "manual")

        await serviceGroup.triggerGracefulShutdown()
    }

    func test_startSpan_onSpanEnd_whenExecutableNameIsSet_includesExecutableNameInFallbackService() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let exporter = OTelStreamingSpanExporter()
        var batches = await exporter.batches.makeAsyncIterator()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:],
            resourceDetection: .manual(OTelResource(attributes: ["process.executable.name": "swift"]))
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)

        Task {
            try await serviceGroup.run()
        }

        let span = tracer.startSpan("1")
        span.end()

        let batch1 = await batches.next()
        let finishedSpan = try XCTUnwrap(batch1?.first)
        XCTAssertEqual(finishedSpan.resource.attributes["service.name"]?.toSpanAttribute(), "unknown_service:swift")

        await serviceGroup.triggerGracefulShutdown()
    }

    func test_startSpan_onSpanEnd_whenExecutableNameIsNotSet_usesFallbackServiceName() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let exporter = OTelStreamingSpanExporter()
        var batches = await exporter.batches.makeAsyncIterator()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:],
            resourceDetection: .disabled
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)

        Task {
            try await serviceGroup.run()
        }

        let span = tracer.startSpan("1")
        span.end()

        let batch1 = await batches.next()
        let finishedSpan = try XCTUnwrap(batch1?.first)
        XCTAssertEqual(finishedSpan.resource.attributes["service.name"]?.toSpanAttribute(), "unknown_service")

        await serviceGroup.triggerGracefulShutdown()
    }

    func test_startSpan_onSpanEnd_whenResourceDetectionTimedOut_usesFallbackServiceName() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let exporter = OTelStreamingSpanExporter()
        var batches = await exporter.batches.makeAsyncIterator()
        let processor = OTelSimpleSpanProcessor(exporter: exporter)
        let clock = TestClock()

        struct TimeoutResourceDetector: OTelResourceDetector {
            let description = "timeout"

            let onResource: @Sendable () async -> Void

            func resource() async throws -> OTelResource {
                await onResource()
                try await Task.sleep(for: .seconds(1))
                return OTelResource(attributes: ["service.name": "timeout"])
            }
        }

        let resourceDetector = TimeoutResourceDetector {
            var sleeps = clock.sleepCalls.makeAsyncIterator()
            await sleeps.next()
            // advance past timeout
            clock.advance(by: .seconds(2))
        }

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:],
            resourceDetection: .automatic(additionalDetectors: [resourceDetector]),
            resourceDetectionTimeout: .seconds(1),
            clock: clock
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)

        Task {
            try await serviceGroup.run()
        }

        let span = tracer.startSpan("1")
        span.end()

        let batch1 = await batches.next()
        let finishedSpan = try XCTUnwrap(batch1?.first)
        XCTAssertEqual(finishedSpan.resource.attributes["service.name"]?.toSpanAttribute(), "unknown_service")

        await serviceGroup.triggerGracefulShutdown()
    }

    func test_forceFlush_forceFlushesProcessor() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let sampler = OTelConstantSampler(isOn: true)
        let propagator = OTelW3CPropagator()
        let exporter = OTelStreamingSpanExporter()
        let clock = TestClock()
        let processor = OTelBatchSpanProcessor(exporter: exporter, configuration: .init(environment: [:]), clock: clock)

        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: sampler,
            propagator: propagator,
            processor: processor,
            environment: [:]
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)

        Task {
            try await serviceGroup.run()
        }

        // We use the processor's first sleep as an indicator for when the tracer started running.
        var sleeps = clock.sleepCalls.makeAsyncIterator()
        await sleeps.next()

        let span = tracer.startSpan("test")
        span.end()

        tracer.forceFlush()

        var batches = await exporter.batches.makeAsyncIterator()
        let batch = await batches.next()

        XCTAssertEqual(try XCTUnwrap(batch).map(\.operationName), ["test"])
    }

    // MARK: - Instrument

    func test_inject_withSpanContext_callsPropagator() async {
        let idGenerator = OTelRandomIDGenerator()
        let propagator = OTelInMemoryPropagator()
        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: OTelConstantSampler(isOn: true),
            propagator: propagator,
            processor: OTelNoOpSpanProcessor(),
            environment: [:]
        )

        var context = ServiceContext.topLevel
        let spanContext = OTelSpanContext(
            traceID: idGenerator.nextTraceID(),
            spanID: idGenerator.nextSpanID(),
            parentSpanID: idGenerator.nextSpanID(),
            traceFlags: .sampled,
            traceState: nil,
            isRemote: false
        )
        context.spanContext = spanContext

        var dictionary = [String: String]()
        tracer.inject(context, into: &dictionary, using: DictionaryInjector())
        XCTAssertEqual(propagator.injectedSpanContexts, [spanContext])
    }

    func test_inject_withoutSpanContext_doesNotCallPropagator() async {
        let propagator = OTelInMemoryPropagator()
        let tracer = await OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelConstantSampler(isOn: true),
            propagator: propagator,
            processor: OTelNoOpSpanProcessor(),
            environment: [:]
        )

        var dictionary = [String: String]()
        tracer.inject(.topLevel, into: &dictionary, using: DictionaryInjector())
        XCTAssertTrue(propagator.injectedSpanContexts.isEmpty)
    }

    func test_extract_callsPropagator() async throws {
        let idGenerator = OTelRandomIDGenerator()
        let spanContext = OTelSpanContext(
            traceID: idGenerator.nextTraceID(),
            spanID: idGenerator.nextSpanID(),
            parentSpanID: idGenerator.nextSpanID(),
            traceFlags: .sampled,
            traceState: nil,
            isRemote: false
        )
        let propagator = OTelInMemoryPropagator(extractionResult: .success(spanContext))
        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: OTelConstantSampler(isOn: true),
            propagator: propagator,
            processor: OTelNoOpSpanProcessor(),
            environment: [:]
        )

        var context = ServiceContext.topLevel
        let dictionary = ["foo": "bar"]

        tracer.extract(dictionary, into: &context, using: DictionaryExtractor())

        XCTAssertEqual(context.spanContext, spanContext)
        XCTAssertEqual(try XCTUnwrap(propagator.extractedCarriers as? [[String: String]]), [dictionary])
    }

    func test_extract_whenPropagatorFails_keepsRunning() async throws {
        struct TestError: Error {}
        let idGenerator = OTelRandomIDGenerator()
        let exporter = OTelStreamingSpanExporter()
        let clock = TestClock()
        let processor = OTelBatchSpanProcessor(exporter: exporter, configuration: .init(environment: [:]), clock: clock)
        let propagator = OTelInMemoryPropagator(extractionResult: .failure(TestError()))
        let tracer = await OTelTracer(
            idGenerator: idGenerator,
            sampler: OTelConstantSampler(isOn: true),
            propagator: propagator,
            processor: processor,
            environment: [:]
        )

        let logger = Logger(label: #function)
        let serviceGroup = ServiceGroup(services: [tracer], logger: logger)
        Task {
            try await serviceGroup.run()
        }

        var context = ServiceContext.topLevel
        tracer.extract([:], into: &context, using: DictionaryExtractor())

        let span = tracer.startSpan("test")
        span.end()

        // We use the processor's first sleep as an indicator for when the tracer started running.
        var sleeps = clock.sleepCalls.makeAsyncIterator()
        await sleeps.next()

        await serviceGroup.triggerGracefulShutdown()

        var batches = await exporter.batches.makeAsyncIterator()
        let batch = await batches.next()
        XCTAssertEqual(try XCTUnwrap(batch).map(\.operationName), ["test"])
    }
}
