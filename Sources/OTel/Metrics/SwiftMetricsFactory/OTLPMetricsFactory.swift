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
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftPrometheus open source project
//
// Copyright (c) 2018-2023 SwiftPrometheus project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftPrometheus project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CoreMetrics

/// A Swift Metrics `MetricsFactory` implementation backed by ``OTelMetricRegistry``.
///
/// - TODO: Review the API surface we want to provide.
///
///   Right now, this is a wrapper type around the ``OTelMetricRegistry`` which adds some configuration. The API is
///   similar to what is in Swift Prometheus, but we might not need to layer this way.
///
///   Specifically, Swift Prometheus provides public API on the registry itself for directly creating and exporting
///   metrics, without using the Swift Metrics API.
///
///   Currently, the registry in this package is opaque, which begs the question: maybe the registry type should be
///   internal and we just have this factory be the public API for now and defer making the registry public to if/when
///   we want to extend this package to provide direct OTel funcionality.
@_spi(Metrics)
public struct OTLPMetricsFactory: Sendable {
    private static let _defaultRegistry = OTelMetricRegistry()

    /// The shared, default registry.
    public static var defaultRegistry: OTelMetricRegistry {
        _defaultRegistry
    }

    /// The underlying registry that provides the handler for the Swift Metrics API.
    public var registry: OTelMetricRegistry

    /// The default bucket upper bounds for duration histograms created for a Swift Metrics `Timer`.
    public var defaultDurationHistogramBuckets: [Duration]

    /// The bucket upper bounds for duration histograms created for a Swift Metrics `Timer` with a specific label.
    public var durationHistogramBuckets: [String: [Duration]]

    /// The default bucket upper bounds for value histograms created for a Swift Metrics `Recorder`.
    public var defaultValueHistogramBuckets: [Double]

    /// The bucket upper bounds for value histograms created for a Swift Metrics `Recorder` with a specific label.
    public var valueHistogramBuckets: [String: [Double]]

    /// A closure to modify the name and labels used in the Swift Metrics API.
    ///
    /// This allows users to override the metadata for metrics recorded by third party packages.
    public var nameAndLabelSanitizer: @Sendable (_ name: String, _ labels: [(String, String)]) -> (String, [(String, String)])

    /// Create a new ``OTLPMetricsFactory``.
    ///
    /// - Parameter registry: The registry for metric instruments.
    public init(registry: OTelMetricRegistry = Self.defaultRegistry) {
        self.registry = registry

        durationHistogramBuckets = [:]
        defaultDurationHistogramBuckets = [
            .zero,
            .milliseconds(5),
            .milliseconds(10),
            .milliseconds(25),
            .milliseconds(50),
            .milliseconds(75),
            .milliseconds(100),
            .milliseconds(250),
            .milliseconds(500),
            .milliseconds(750),
            .milliseconds(1000),
            .milliseconds(2500),
            .milliseconds(5000),
            .milliseconds(7500),
            .milliseconds(10000),
        ]

        valueHistogramBuckets = [:]
        defaultValueHistogramBuckets = [
            0,
            5,
            10,
            25,
            50,
            75,
            100,
            250,
            500,
            750,
            1000,
            2500,
            5000,
            7500,
            10000,
        ]

        nameAndLabelSanitizer = { ($0, $1) }
    }
}

extension OTLPMetricsFactory: CoreMetrics.MetricsFactory {
    public func makeCounter(label: String, dimensions: [(String, String)]) -> CoreMetrics.CounterHandler {
        let (label, dimensions) = nameAndLabelSanitizer(label, dimensions)
        let (unit, description, attributes) = extractIdentifyingFieldsAndAttributes(from: dimensions)
        return registry.makeCounter(name: label, unit: unit, description: description, attributes: attributes)
    }

    public func makeFloatingPointCounter(label: String, dimensions: [(String, String)]) -> CoreMetrics.FloatingPointCounterHandler {
        let (label, dimensions) = nameAndLabelSanitizer(label, dimensions)
        let (unit, description, attributes) = extractIdentifyingFieldsAndAttributes(from: dimensions)
        return registry.makeCounter(name: label, unit: unit, description: description, attributes: attributes)
    }

    public func makeRecorder(
        label: String,
        dimensions: [(String, String)],
        aggregate: Bool
    ) -> CoreMetrics.RecorderHandler {
        let (label, dimensions) = nameAndLabelSanitizer(label, dimensions)
        let (unit, description, attributes) = extractIdentifyingFieldsAndAttributes(from: dimensions)
        guard aggregate else {
            return registry.makeGauge(name: label, unit: unit, description: description, attributes: attributes)
        }
        let buckets = valueHistogramBuckets[label] ?? defaultValueHistogramBuckets
        return registry.makeValueHistogram(name: label, unit: unit, description: description, attributes: attributes, buckets: buckets)
    }

    public func makeMeter(label: String, dimensions: [(String, String)]) -> CoreMetrics.MeterHandler {
        let (label, dimensions) = nameAndLabelSanitizer(label, dimensions)
        let (unit, description, attributes) = extractIdentifyingFieldsAndAttributes(from: dimensions)
        return registry.makeGauge(name: label, unit: unit, description: description, attributes: attributes)
    }

    public func makeTimer(label: String, dimensions: [(String, String)]) -> CoreMetrics.TimerHandler {
        let (label, dimensions) = nameAndLabelSanitizer(label, dimensions)
        let (unit, description, attributes) = extractIdentifyingFieldsAndAttributes(from: dimensions)
        let buckets = durationHistogramBuckets[label] ?? defaultDurationHistogramBuckets
        return registry.makeDurationHistogram(name: label, unit: unit, description: description, attributes: attributes, buckets: buckets)
    }

    public func destroyCounter(_ handler: CoreMetrics.CounterHandler) {
        guard let counter = handler as? Counter else {
            return
        }
        registry.unregisterCounter(counter)
    }

    public func destroyFloatingPointCounter(_ handler: FloatingPointCounterHandler) {
        guard let counter = handler as? Counter else {
            return
        }
        registry.unregisterCounter(counter)
    }

    public func destroyRecorder(_ handler: CoreMetrics.RecorderHandler) {
        switch handler {
        case let gauge as Gauge:
            registry.unregisterGauge(gauge)
        case let histogram as Histogram<Double>:
            registry.unregisterValueHistogram(histogram)
        default:
            break
        }
    }

    public func destroyMeter(_ handler: CoreMetrics.MeterHandler) {
        guard let gauge = handler as? Gauge else {
            return
        }
        registry.unregisterGauge(gauge)
    }

    public func destroyTimer(_ handler: CoreMetrics.TimerHandler) {
        guard let histogram = handler as? Histogram<Duration> else {
            return
        }
        registry.unregisterDurationHistogram(histogram)
    }
}

// MARK: - Helpers

extension OTLPMetricsFactory {
    /// Returns the values for keys `unit` and `description`, if they are present in the array.
    private func extractIdentifyingFieldsAndAttributes(from dimensions: [(String, String)]) -> (unit: String?, description: String?, Set<Attribute>) {
        var unit: String?
        var description: String?
        var attributes = Set<Attribute>()
        for (key, value) in dimensions {
            switch key {
            case "unit": unit = value
            case "description": description = value
            default: attributes.insert(Attribute(key: key, value: value))
            }
        }
        return (unit, description, attributes)
    }
}
