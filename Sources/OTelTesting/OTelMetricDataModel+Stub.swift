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

@testable @_spi(Metrics) import OTel
import Tracing

@_spi(Metrics)
extension OTelResource {
    package static func stub(
        attributes: SpanAttributes = [:]
    ) -> Self {
        .init(attributes: attributes)
    }
}

@_spi(Metrics)
extension OTelResourceMetrics {
    package static func stub(
        resource: OTelResource? = nil,
        scopeMetrics: [OTelScopeMetrics] = []
    ) -> Self {
        .init(
            resource: resource,
            scopeMetrics: scopeMetrics
        )
    }
}

@_spi(Metrics)
extension OTelScopeMetrics {
    package static func stub(
        scope: OTelInstrumentationScope? = nil,
        metrics: [OTelMetricPoint] = []
    ) -> Self {
        .init(
            scope: scope,
            metrics: metrics
        )
    }
}

@_spi(Metrics)
extension OTelInstrumentationScope {
    package static func stub(
        name: String? = nil,
        version: String? = nil,
        attributes: [OTelAttribute] = [],
        droppedAttributeCount: Int32 = 0
    ) -> Self {
        .init(
            name: name,
            version: version,
            attributes: attributes,
            droppedAttributeCount: droppedAttributeCount
        )
    }
}

@_spi(Metrics)
extension OTelMetricPoint {
    package static func stub(
        name: String = "test",
        description: String = "",
        unit: String = "",
        data: OTelMetricData = .sum(.stub())
    ) -> Self {
        .init(
            name: name,
            description: description,
            unit: unit,
            data: data
        )
    }
}

@_spi(Metrics)
extension OTelSum {
    package static func stub(
        points: [OTelNumberDataPoint] = [],
        aggregationTemporality: OTelAggregationTemporailty = .cumulative,
        monotonic: Bool = true
    ) -> Self {
        .init(
            points: points,
            aggregationTemporality: aggregationTemporality,
            monotonic: monotonic
        )
    }
}

@_spi(Metrics)
extension OTelGauge {
    package static func stub(
        points: [OTelNumberDataPoint] = []
    ) -> Self {
        .init(points: points)
    }
}

@_spi(Metrics)
extension OTelHistogram {
    package static func stub(
        aggregationTemporality: OTelAggregationTemporailty = .cumulative,
        points: [OTelHistogramDataPoint] = []
    ) -> Self {
        .init(
            aggregationTemporality: aggregationTemporality,
            points: points
        )
    }
}

@_spi(Metrics)
extension OTelAttribute {
    package static func stub(
        key: String = "key",
        value: String = "value"
    ) -> Self {
        .init(
            key: key,
            value: value
        )
    }
}

@_spi(Metrics)
extension OTelNumberDataPoint {
    package static func stub(
        attributes: [OTelAttribute] = [],
        startTimeNanosecondsSinceEpoch: UInt64? = nil,
        timeNanosecondsSinceEpoch: UInt64 = 0,
        value: Value = .int64(0),
        exemplars: [OTelExemplar] = [],
        flags: [Flags] = []
    ) -> Self {
        .init(
            attributes: attributes,
            startTimeNanosecondsSinceEpoch: startTimeNanosecondsSinceEpoch,
            timeNanosecondsSinceEpoch: timeNanosecondsSinceEpoch,
            value: value,
            exemplars: exemplars,
            flags: flags
        )
    }
}

@_spi(Metrics)
extension OTelHistogramDataPoint {
    package static func stub(
        attributes: [OTelAttribute] = [],
        startTimeNanosecondsSinceEpoch: UInt64? = nil,
        timeNanosecondsSinceEpoch: UInt64 = 0,
        count: UInt64 = 0,
        sum: Double? = nil,
        min: Double? = nil,
        max: Double? = nil,
        buckets: [Bucket] = [],
        exemplars: [OTelExemplar] = []
    ) -> Self {
        .init(
            attributes: attributes,
            startTimeNanosecondsSinceEpoch: startTimeNanosecondsSinceEpoch,
            timeNanosecondsSinceEpoch: timeNanosecondsSinceEpoch,
            count: count,
            sum: sum,
            min: min,
            max: max,
            buckets: buckets,
            exemplars: exemplars
        )
    }
}

@_spi(Metrics)
extension OTelHistogramDataPoint.Bucket {
    package static func stub(
        upperBound: Double = 0,
        count: UInt64 = 0
    ) -> Self {
        .init(
            upperBound: upperBound,
            count: count
        )
    }
}

@_spi(Metrics)
extension OTelExemplar {
    package static func stub(
        spanID: OTelSpanID? = nil,
        observationTimeNanosecondsSinceEpoch: UInt64 = 0,
        filteredAttributes: [OTelAttribute] = []
    ) -> Self {
        .init(
            spanID: spanID,
            observationTimeNanosecondsSinceEpoch: observationTimeNanosecondsSinceEpoch,
            filteredAttributes: filteredAttributes
        )
    }
}
