//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CoreMetrics
@testable @_spi(Metrics) import OTel
import OTelTesting
import XCTest

final class OTLPMetricsFactoryTests: XCTestCase {
    func test_makeCounter_returnsOTelCounter() throws {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)

        let counter = try XCTUnwrap(factory.makeCounter(label: "c", dimensions: [("x", "1")]) as? OTel.Counter)
        XCTAssertEqual(counter.name, "c")
        XCTAssertEqual(counter.attributes, Set([("x", "1")]))
    }

    func test_makeFloatingPointCounter_returnsOTelCounter() throws {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)

        let counter = try XCTUnwrap(factory.makeFloatingPointCounter(label: "c", dimensions: [("x", "1")]) as? OTel.Counter)
        XCTAssertEqual(counter.name, "c")
        XCTAssertEqual(counter.attributes, Set([("x", "1")]))
    }

    func testMakeCounterAndMakeFloatingPointCounterReturnSameOTelCounter() throws {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)

        XCTAssertIdentical(
            factory.makeCounter(label: "c", dimensions: [("x", "1")]),
            factory.makeFloatingPointCounter(label: "c", dimensions: [("x", "1")])
        )
    }

    func test_makeMeter_returnsOTelGauge() throws {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)

        let meter = factory.makeMeter(label: "m", dimensions: [("x", "1")])
        let gauge = try XCTUnwrap(meter as? OTel.Gauge)
        XCTAssertEqual(gauge.name, "m")
        XCTAssertEqual(gauge.attributes, Set([("x", "1")]))
    }

    func test_makeTimer_returnsOTelDurationHistogram() throws {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)

        let timer = factory.makeTimer(label: "t", dimensions: [("x", "1")])
        let histogram = try XCTUnwrap(timer as? DurationHistogram)
        XCTAssertEqual(histogram.name, "t")
        XCTAssertEqual(histogram.attributes, Set([("x", "1")]))
    }

    func test_makeRecorderWithoutAggregation_returnsOTelGauge() throws {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)

        let recorder = factory.makeRecorder(label: "r", dimensions: [("x", "1")], aggregate: false)
        let gauge = try XCTUnwrap(recorder as? OTel.Gauge)
        XCTAssertEqual(gauge.name, "r")
        XCTAssertEqual(gauge.attributes, Set([("x", "1")]))
    }

    func test_makeRecorderWithAggregation_returnsOTelValueHistogram() throws {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)

        let recorder = factory.makeRecorder(label: "r", dimensions: [("x", "1")], aggregate: true)
        let histogram = try XCTUnwrap(recorder as? ValueHistogram)
        XCTAssertEqual(histogram.name, "r")
        XCTAssertEqual(histogram.attributes, Set([("x", "1")]))
    }

    func test_makeTimer_customBuckets() throws {
        let registry = OTelMetricRegistry()
        var factory = OTLPMetricsFactory(registry: registry)
        factory.defaultDurationHistogramBuckets = [.milliseconds(100), .milliseconds(200)]
        factory.durationHistogramBuckets = ["custom": [.milliseconds(300), .milliseconds(400)]]

        do {
            let timer = factory.makeTimer(label: "default", dimensions: [])
            let histogram = try XCTUnwrap(timer as? DurationHistogram)
            histogram.assertStateEquals(count: 0, sum: .zero, buckets: [
                (bound: .milliseconds(100), count: 0),
                (bound: .milliseconds(200), count: 0),
            ])
        }

        do {
            let timer = factory.makeTimer(label: "custom", dimensions: [])
            let histogram = try XCTUnwrap(timer as? DurationHistogram)
            histogram.assertStateEquals(count: 0, sum: .zero, buckets: [
                (bound: .milliseconds(300), count: 0),
                (bound: .milliseconds(400), count: 0),
            ])
        }
    }

    func test_makeRecorder_customBuckets() throws {
        let registry = OTelMetricRegistry()
        var factory = OTLPMetricsFactory(registry: registry)
        factory.defaultValueHistogramBuckets = [0.1, 0.2]
        factory.valueHistogramBuckets = ["custom": [0.3, 0.4]]

        do {
            let recorder = factory.makeRecorder(label: "default", dimensions: [], aggregate: true)
            let histogram = try XCTUnwrap(recorder as? ValueHistogram)
            histogram.assertStateEquals(count: 0, sum: 0, buckets: [
                (bound: 0.1, count: 0),
                (bound: 0.2, count: 0),
            ])
        }

        do {
            let recorder = factory.makeRecorder(label: "custom", dimensions: [], aggregate: true)
            let histogram = try XCTUnwrap(recorder as? ValueHistogram)
            histogram.assertStateEquals(count: 0, sum: 0, buckets: [
                (bound: 0.3, count: 0),
                (bound: 0.4, count: 0),
            ])
        }
    }

    func test_Counter_methods() {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)
        let counter = factory.makeCounter(label: "c", dimensions: [("x", "1")])

        (counter as? OTel.Counter)?.assertStateEquals(integerPart: 0, doublePart: 0.0)
        counter.increment(by: 2)
        (counter as? OTel.Counter)?.assertStateEquals(integerPart: 2, doublePart: 0.0)
        counter.increment(by: 2)
        (counter as? OTel.Counter)?.assertStateEquals(integerPart: 4, doublePart: 0.0)
        counter.reset()
        (counter as? OTel.Counter)?.assertStateEquals(integerPart: 0, doublePart: 0.0)
    }

    func test_FloatingPointCounter_methods() {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)
        let counter = factory.makeFloatingPointCounter(label: "c", dimensions: [("x", "1")])

        (counter as? OTel.Counter)?.assertStateEquals(integerPart: 0, doublePart: 0.0)
        counter.increment(by: 2)
        (counter as? OTel.Counter)?.assertStateEquals(integerPart: 0, doublePart: 2.0)
        counter.increment(by: Double(2.5))
        (counter as? OTel.Counter)?.assertStateEquals(integerPart: 0, doublePart: 4.5)
        counter.reset()
        (counter as? OTel.Counter)?.assertStateEquals(integerPart: 0, doublePart: 0.0)
    }

    func test_Meter_methods() {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)
        let meter = factory.makeMeter(label: "m", dimensions: [("x", "1")])

        meter.set(43.5)
        XCTAssertEqual((meter as? OTel.Gauge)?.doubleAtomicValue, 43.5)
        meter.increment(by: 6.5)
        XCTAssertEqual((meter as? OTel.Gauge)?.doubleAtomicValue, 50.0)
        meter.decrement(by: 8.0)
        XCTAssertEqual((meter as? OTel.Gauge)?.doubleAtomicValue, 42.0)
        meter.set(Int64(6))
        XCTAssertEqual((meter as? OTel.Gauge)?.doubleAtomicValue, 6.0)
    }

    func test_Recorder_withoutAggregration_methods() throws {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)
        let recorder = factory.makeRecorder(label: "r", dimensions: [("x", "1")], aggregate: false)

        XCTAssertEqual((recorder as? OTel.Gauge)?.doubleAtomicValue, 0.0)
        recorder.record(Int64(2))
        XCTAssertEqual((recorder as? OTel.Gauge)?.doubleAtomicValue, 2.0)
        recorder.record(Double(-3.1))
        XCTAssertEqual((recorder as? OTel.Gauge)?.doubleAtomicValue, -3.1)
        recorder.record(Int64(42))
        XCTAssertEqual((recorder as? OTel.Gauge)?.doubleAtomicValue, 42)
    }

    func test_Recorder_withAggregration_methods() throws {
        let registry = OTelMetricRegistry()
        var factory = OTLPMetricsFactory(registry: registry)
        factory.defaultValueHistogramBuckets = [0.1, 0.25, 0.5, 1]
        let recorder = factory.makeRecorder(label: "r", dimensions: [("x", "1")], aggregate: true)

        (recorder as? ValueHistogram)?.assertStateEquals(count: 0, sum: 0, buckets: [
            (bound: 0.10, count: 0),
            (bound: 0.25, count: 0),
            (bound: 0.50, count: 0),
            (bound: 1.00, count: 0),
        ])

        recorder.record(0.4)
        (recorder as? ValueHistogram)?.assertStateEquals(count: 1, sum: 0.4, buckets: [
            (bound: 0.10, count: 0),
            (bound: 0.25, count: 0),
            (bound: 0.50, count: 1),
            (bound: 1.00, count: 1),
        ])

        recorder.record(0.6)
        (recorder as? ValueHistogram)?.assertStateEquals(count: 2, sum: 1.0, buckets: [
            (bound: 0.10, count: 0),
            (bound: 0.25, count: 0),
            (bound: 0.50, count: 1),
            (bound: 1.00, count: 2),
        ])

        recorder.record(1.2)
        (recorder as? ValueHistogram)?.assertStateEquals(count: 3, sum: 2.2, buckets: [
            (bound: 0.10, count: 0),
            (bound: 0.25, count: 0),
            (bound: 0.50, count: 1),
            (bound: 1.00, count: 2),
        ])

        recorder.record(0.01)
        (recorder as? ValueHistogram)?.assertStateEquals(count: 4, sum: 2.21, buckets: [
            (bound: 0.10, count: 1),
            (bound: 0.25, count: 1),
            (bound: 0.50, count: 2),
            (bound: 1.00, count: 3),
        ])

        recorder.record(Int64(1))
        (recorder as? ValueHistogram)?.assertStateEquals(count: 5, sum: 3.21, buckets: [
            (bound: 0.10, count: 1),
            (bound: 0.25, count: 1),
            (bound: 0.50, count: 2),
            (bound: 1.00, count: 4),
        ])

        recorder.record(Int64(2))
        (recorder as? ValueHistogram)?.assertStateEquals(count: 6, sum: 5.21, buckets: [
            (bound: 0.10, count: 1),
            (bound: 0.25, count: 1),
            (bound: 0.50, count: 2),
            (bound: 1.00, count: 4),
        ])
    }

    func test_Timer_methods() throws {
        let registry = OTelMetricRegistry()
        var factory = OTLPMetricsFactory(registry: registry)
        factory.defaultDurationHistogramBuckets = [
            .nanoseconds(100),
            .nanoseconds(250),
            .nanoseconds(500),
            .microseconds(1),
        ]
        let timer = factory.makeTimer(label: "t", dimensions: [("x", "1")])

        (timer as? DurationHistogram)?.assertStateEquals(count: 0, sum: .zero, buckets: [
            (bound: .nanoseconds(100), count: 0),
            (bound: .nanoseconds(250), count: 0),
            (bound: .nanoseconds(500), count: 0),
            (bound: .microseconds(1), count: 0),
        ])

        timer.recordNanoseconds(400)
        (timer as? DurationHistogram)?.assertStateEquals(count: 1, sum: .nanoseconds(400), buckets: [
            (bound: .nanoseconds(100), count: 0),
            (bound: .nanoseconds(250), count: 0),
            (bound: .nanoseconds(500), count: 1),
            (bound: .microseconds(1), count: 1),
        ])

        timer.recordNanoseconds(600)
        (timer as? DurationHistogram)?.assertStateEquals(count: 2, sum: .nanoseconds(1000), buckets: [
            (bound: .nanoseconds(100), count: 0),
            (bound: .nanoseconds(250), count: 0),
            (bound: .nanoseconds(500), count: 1),
            (bound: .microseconds(1), count: 2),
        ])

        timer.recordNanoseconds(1200)
        (timer as? DurationHistogram)?.assertStateEquals(count: 3, sum: .nanoseconds(2200), buckets: [
            (bound: .nanoseconds(100), count: 0),
            (bound: .nanoseconds(250), count: 0),
            (bound: .nanoseconds(500), count: 1),
            (bound: .microseconds(1), count: 2),
        ])

        timer.recordNanoseconds(80)
        (timer as? DurationHistogram)?.assertStateEquals(count: 4, sum: .nanoseconds(2280), buckets: [
            (bound: .nanoseconds(100), count: 1),
            (bound: .nanoseconds(250), count: 1),
            (bound: .nanoseconds(500), count: 2),
            (bound: .microseconds(1), count: 3),
        ])
    }

    func test_reregister_withoutDimensions() {
        let duplicateRegistrationHandler = RecordingDuplicateRegistrationHandler()
        let registry = OTelMetricRegistry(duplicateRegistrationHandler: duplicateRegistrationHandler)
        let factory = OTLPMetricsFactory(registry: registry)

        // Here we test a few things at once:
        // 1. That we can destroy using the handler.
        // 2. That double destroy is OK (i.e. doesn't crash).
        // 3. That, once destroyed, we can reuse the handle.
        // 4. That the reuse did not result in a duplicate registration handler call.

        let c = factory.makeCounter(label: "name", dimensions: [])
        factory.destroyCounter(c)
        factory.destroyCounter(c)

        let f = factory.makeFloatingPointCounter(label: "name", dimensions: [])
        factory.destroyFloatingPointCounter(f)
        factory.destroyFloatingPointCounter(f)

        let m = factory.makeMeter(label: "name", dimensions: [])
        factory.destroyMeter(m)
        factory.destroyMeter(m)

        let r = factory.makeRecorder(label: "name", dimensions: [], aggregate: true)
        factory.destroyRecorder(r)
        factory.destroyRecorder(r)

        let r_ = factory.makeRecorder(label: "name", dimensions: [], aggregate: false)
        factory.destroyRecorder(r_)
        factory.destroyRecorder(r_)

        let t = factory.makeTimer(label: "name", dimensions: [])
        factory.destroyTimer(t)
        factory.destroyTimer(t)

        _ = factory.makeCounter(label: "name", dimensions: [])

        XCTAssertEqual(duplicateRegistrationHandler.invocations.withLockedValue { $0 }.count, 0)
    }

    func test_reregister_withDimensions() {
        let duplicateRegistrationHandler = RecordingDuplicateRegistrationHandler()
        let registry = OTelMetricRegistry(duplicateRegistrationHandler: duplicateRegistrationHandler)
        let factory = OTLPMetricsFactory(registry: registry)

        let c1 = factory.makeCounter(label: "name", dimensions: [("a", "1")])
        let c2 = factory.makeCounter(label: "name", dimensions: [("b", "1")])
        factory.destroyCounter(c1)
        factory.destroyCounter(c1)
        factory.destroyCounter(c2)
        factory.destroyCounter(c2)
        XCTAssert(registry.storage.withLockedValue { $0 }.registrations.isEmpty)

        let f1 = factory.makeFloatingPointCounter(label: "name", dimensions: [("a", "1")])
        let f2 = factory.makeFloatingPointCounter(label: "name", dimensions: [("b", "1")])
        factory.destroyFloatingPointCounter(f1)
        factory.destroyFloatingPointCounter(f1)
        factory.destroyFloatingPointCounter(f2)
        factory.destroyFloatingPointCounter(f2)
        XCTAssert(registry.storage.withLockedValue { $0 }.registrations.isEmpty)

        let m1 = factory.makeMeter(label: "name", dimensions: [("a", "1")])
        let m2 = factory.makeMeter(label: "name", dimensions: [("b", "1")])
        factory.destroyMeter(m1)
        factory.destroyMeter(m1)
        factory.destroyMeter(m2)
        factory.destroyMeter(m2)
        XCTAssert(registry.storage.withLockedValue { $0 }.registrations.isEmpty)

        let r1 = factory.makeRecorder(label: "name", dimensions: [("a", "1")], aggregate: true)
        let r2 = factory.makeRecorder(label: "name", dimensions: [("b", "1")], aggregate: true)
        factory.destroyRecorder(r1)
        factory.destroyRecorder(r1)
        factory.destroyRecorder(r2)
        factory.destroyRecorder(r2)
        XCTAssert(registry.storage.withLockedValue { $0 }.registrations.isEmpty)

        let t1 = factory.makeTimer(label: "name", dimensions: [("a", "1")])
        let t2 = factory.makeTimer(label: "name", dimensions: [("b", "1")])
        factory.destroyTimer(t1)
        factory.destroyTimer(t1)
        factory.destroyTimer(t2)
        factory.destroyTimer(t2)
        XCTAssert(registry.storage.withLockedValue { $0 }.registrations.isEmpty)

        _ = factory.makeCounter(label: "name", dimensions: [])

        XCTAssertEqual(registry.storage.withLockedValue { $0 }.registrations.count, 1)
        XCTAssertEqual(duplicateRegistrationHandler.invocations.withLockedValue { $0 }.count, 0)
    }

    func test_FactoryInitializer_usesSingletonRegistryByDefault() {
        XCTAssertIdentical(
            OTLPMetricsFactory().registry,
            OTLPMetricsFactory().registry
        )
    }

    func test_destroy_gracefullyHandlesBogusHandles() {
        let registry = OTelMetricRegistry()
        let factory = OTLPMetricsFactory(registry: registry)

        final class NonOTelMetricsHandler: CounterHandler, FloatingPointCounterHandler, MeterHandler, RecorderHandler, TimerHandler {
            func decrement(by: Double) {}
            func increment(by: Int64) {}
            func increment(by: Double) {}
            func record(_ value: Int64) {}
            func record(_ value: Double) {}
            func recordNanoseconds(_ duration: Int64) {}
            func reset() {}
            func set(_ value: Int64) {}
            func set(_ value: Double) {}
        }

        factory.destroyCounter(NonOTelMetricsHandler())
        factory.destroyFloatingPointCounter(NonOTelMetricsHandler())
        factory.destroyMeter(NonOTelMetricsHandler())
        factory.destroyRecorder(NonOTelMetricsHandler())
        factory.destroyTimer(NonOTelMetricsHandler())
    }

    func test_defaultHistogramBuckets_matchOTelSpecification() {
        // https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#explicit-bucket-histogram-aggregation
        let defaultBucketsFromOTelSpec = [0.0, 5, 10, 25, 50, 75, 100, 250, 500, 750, 1000, 2500, 5000, 7500, 10000]
        let factory = OTLPMetricsFactory()
        XCTAssertEqual(factory.defaultValueHistogramBuckets, defaultBucketsFromOTelSpec)
        XCTAssertEqual(factory.defaultDurationHistogramBuckets, defaultBucketsFromOTelSpec.map { .milliseconds($0) })
    }
}
