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

import OpenTelemetry

extension Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest {
    init<C: Collection>(_ batch: C) where C.Element == OTel.RecordedMetric {
        self = .with { request in
            request.resourceMetrics = batch.reduce(into: []) { r, metric in
                let metricResource = Opentelemetry_Proto_Resource_V1_Resource(metric.resource)
                if let existingIndex = r.firstIndex(where: { $0.resource == metricResource }) {
                    r[existingIndex].scopeMetrics[0].metrics.append(.init(metric))
                } else {
                    r.append(.with {
                        $0.resource = metricResource
                        $0.scopeMetrics = [.init(metrics: [metric])]
                    })
                }
            }
        }
    }
}

extension Opentelemetry_Proto_Metrics_V1_ScopeMetrics {
    init(metrics: [OTel.RecordedMetric]) {
        self.metrics = metrics.map(Opentelemetry_Proto_Metrics_V1_Metric.init)
    }
}

extension Opentelemetry_Proto_Metrics_V1_Metric {
    init(_ metric: OTel.RecordedMetric) {
        switch metric {
        case .sum(let sum):
            self.name = sum.label
            self.sum = .init(sum)
        case .gauge(let gauge):
            self.name = gauge.label
            self.gauge = .init(gauge)
        case .histogram(let histogram):
            self.name = histogram.label
            self.histogram = .init(histogram)
        case .exponentialHistogram, .summary:
            ()// TODO: Implement
//        case .exponentialHistogram(let histogram):
//            self.exponentialHistogram = .init(histogram, attributes: metric.dimensions)
        }
    }
}

extension Opentelemetry_Proto_Metrics_V1_Sum {
    init(_ sum: OTel.Sum) {
        self.dataPoints = sum.dataPoints.map(Opentelemetry_Proto_Metrics_V1_NumberDataPoint.init)
        self.aggregationTemporality = sum.isCumulative ? .cumulative : .delta
        self.isMonotonic = sum.isMonotonic
    }
}

extension Opentelemetry_Proto_Metrics_V1_Gauge {
    init(_ gauge: OTel.Gauge) {
        self.dataPoints = gauge.dataPoints.map(Opentelemetry_Proto_Metrics_V1_NumberDataPoint.init)
    }
}

extension Opentelemetry_Proto_Metrics_V1_Histogram {
    init(_ histogram: OTel.Histogram) {
        self.dataPoints = histogram.dataPoints.map { dataPoint in
            Opentelemetry_Proto_Metrics_V1_HistogramDataPoint(
                dataPoint: dataPoint,
                attributes: histogram.dimensions
            )
        }
    }
}

extension Opentelemetry_Proto_Metrics_V1_HistogramDataPoint {
    init(dataPoint: OTel.HistogramDataPoint, attributes: [(String, String)]) {
        self.timeUnixNano = dataPoint.unixTimeNanoseconds
        self.startTimeUnixNano = dataPoint.unixTimeNanoseconds
        self.exemplars = [.init(dataPoint: dataPoint)]
        self.attributes = attributes.map { (key, value) in
            var pair = Opentelemetry_Proto_Common_V1_KeyValue()
            var pairValue = Opentelemetry_Proto_Common_V1_AnyValue()
            
            pairValue.value = .stringValue(value)
            
            pair.key = key
            pair.value = pairValue
            
            return pair
        }
    }
}

//extension Opentelemetry_Proto_Metrics_V1_Summary {
//    init(_ summary: OTel.MetricValue.Summary, attributes: [(String, String)]) {
//        self.dataPoints = summary.dataPoints.map { dataPoint in
//            Opentelemetry_Proto_Metrics_V1_SummaryDataPoint(dataPoint, attributes: attributes)
//        }
//    }
//}

//extension Opentelemetry_Proto_Metrics_V1_SummaryDataPoint {
//    init(_ dataPoint: OTel.HistogramDataPoint, attributes: [(String, String)]) {
//        self.timeUnixNano = dataPoint.startTimeUnixNano
//        self.startTimeUnixNano = dataPoint.startTimeUnixNano
//        self.attributes = attributes.map { (key, value) in
//            var pair = Opentelemetry_Proto_Common_V1_KeyValue()
//            var pairValue = Opentelemetry_Proto_Common_V1_AnyValue()
//
//            pairValue.value = .stringValue(value)
//
//            pair.key = key
//            pair.value = pairValue
//
//            return pair
//        }
//    }
//}

extension Opentelemetry_Proto_Metrics_V1_Exemplar {
    init(dataPoint: OTel.HistogramDataPoint) {
        self.timeUnixNano = dataPoint.unixTimeNanoseconds
        
        switch dataPoint.value {
        case .int(let int):
            self.value = .asInt(int)
        case .double(let double):
            self.value = .asDouble(double)
        }
    }
}

extension Opentelemetry_Proto_Metrics_V1_NumberDataPoint {
    init(_ value: OTel.NumericValue) {
        switch value {
        case .int(let int):
            self.value = .asInt(int)
        case .double(let double):
            self.value = .asDouble(double)
        }
    }
}
