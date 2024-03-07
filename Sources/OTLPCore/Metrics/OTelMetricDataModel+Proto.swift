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

@_spi(Metrics) import OTel

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_ResourceMetrics {
    package init(_ resrouceMetrics: OTelResourceMetrics) {
        if let resource = resrouceMetrics.resource {
            self.resource = .init(resource)
        }
        scopeMetrics = resrouceMetrics.scopeMetrics.map(Opentelemetry_Proto_Metrics_V1_ScopeMetrics.init)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Resource_V1_Resource {
    package init(_ resource: OTelResource) {
        attributes = .init(resource.attributes)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_ScopeMetrics {
    package init(_ scopeMetrics: OTelScopeMetrics) {
        if let scope = scopeMetrics.scope {
            self.scope = .init(scope)
        }
        metrics = scopeMetrics.metrics.map(Opentelemetry_Proto_Metrics_V1_Metric.init)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Common_V1_InstrumentationScope {
    package init(_ instrumentationScope: OTelInstrumentationScope) {
        if let name = instrumentationScope.name {
            self.name = name
        }
        if let version = instrumentationScope.version {
            self.version = version
        }
        attributes = .init(instrumentationScope.attributes)
        droppedAttributesCount = UInt32(instrumentationScope.droppedAttributeCount)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_Metric {
    package init(_ metric: OTelMetricPoint) {
        name = metric.name
        description_p = metric.description
        unit = metric.unit
        switch metric.data {
        case .gauge(let gauge):
            self.gauge = .init(gauge)
        case .sum(let sum):
            self.sum = .init(sum)
        case .histogram(let histogram):
            self.histogram = .init(histogram)
        }
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_Gauge {
    package init(_ gauge: OTelGauge) {
        dataPoints = .init(gauge.points)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_Sum {
    package init(_ sum: OTelSum) {
        aggregationTemporality = .init(sum.aggregationTemporality)
        isMonotonic = sum.monotonic
        dataPoints = .init(sum.points)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_AggregationTemporality {
    package init(_ aggregationTemporaility: OTelAggregationTemporailty) {
        switch aggregationTemporaility {
        case .cumulative:
            self = .cumulative
        case .delta:
            self = .delta
        }
    }
}

@_spi(Metrics)
extension [Opentelemetry_Proto_Metrics_V1_NumberDataPoint] {
    package init(_ points: [OTelNumberDataPoint]) {
        self = points.map(Element.init)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_NumberDataPoint {
    package init(_ point: OTelNumberDataPoint) {
        attributes = .init(point.attributes)
        if let startTime = point.startTimeNanosecondsSinceEpoch {
            startTimeUnixNano = startTime
        }
        timeUnixNano = point.timeNanosecondsSinceEpoch
        switch point.value {
        case .double(let value):
            self.value = .asDouble(value)
        case .int64(let value):
            self.value = .asInt(value)
        }
        exemplars = .init(point.exemplars)
    }
}

@_spi(Metrics)
extension [Opentelemetry_Proto_Common_V1_KeyValue] {
    package init(_ attributes: [OTelAttribute]) {
        self = attributes.map(Element.init)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Common_V1_KeyValue {
    package init(_ attribute: OTelAttribute) {
        key = attribute.key
        value = Opentelemetry_Proto_Common_V1_AnyValue(attribute.value)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Common_V1_AnyValue {
    package init(_ string: String) {
        value = .stringValue(string)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_Exemplar {
    package init(_ exemplar: OTelExemplar) {
        // TODO:
    }
}

@_spi(Metrics)
extension [Opentelemetry_Proto_Metrics_V1_Exemplar] {
    package init(_ exemplars: [OTelExemplar]) {
        self = exemplars.map(Element.init)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_Histogram {
    package init(_ histogram: OTelHistogram) {
        aggregationTemporality = .init(histogram.aggregationTemporality)
        dataPoints = .init(histogram.points)
    }
}

@_spi(Metrics)
extension [Opentelemetry_Proto_Metrics_V1_HistogramDataPoint] {
    package init(_ points: [OTelHistogramDataPoint]) {
        self = points.map(Element.init)
    }
}

@_spi(Metrics)
extension Opentelemetry_Proto_Metrics_V1_HistogramDataPoint {
    package init(_ point: OTelHistogramDataPoint) {
        attributes = .init(point.attributes)
        if let startTime = point.startTimeNanosecondsSinceEpoch {
            startTimeUnixNano = startTime
        }
        timeUnixNano = point.timeNanosecondsSinceEpoch
        count = point.count
        if let sum = point.sum {
            self.sum = sum
        }
        if let min = point.min {
            self.min = min
        }
        if let max = point.max {
            self.max = max
        }
        for bucket in point.buckets {
            bucketCounts.append(bucket.count)
            explicitBounds.append(bucket.upperBound)
        }
        exemplars = .init(point.exemplars)
    }
}

@_spi(Metrics)
extension [Opentelemetry_Proto_Metrics_V1_Metric] {
    package init(_ points: [OTelMetricPoint]) {
        self = points.map(Element.init)
    }
}
