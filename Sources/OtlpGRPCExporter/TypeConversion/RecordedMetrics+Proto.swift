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
        self.name = metric.label
//        self.
    }
}
