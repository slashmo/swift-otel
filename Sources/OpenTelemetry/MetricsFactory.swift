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

import struct Dispatch.DispatchWallTime
import Logging
import NIOConcurrencyHelpers
import Metrics

#if os(Linux)
import Glibc
#else
import Darwin
#endif

extension OTel {
    final class MetricsFactory {
        private let resource: OTel.Resource
        private let processor: OTelMetricsProcessor
        
        init(
            resource: OTel.Resource,
            processor: OTelMetricsProcessor
        ) {
            self.resource = resource
            self.processor = processor
        }
    }
}

extension OTel.MetricsFactory: MetricsFactory {
    func makeCounter(label: String, dimensions: [(String, String)]) -> CounterHandler {
        Counter(
            processor: processor,
            resource: resource,
            label: label,
            dimensions: dimensions
        )
    }

    func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> RecorderHandler {
        if aggregate {
            return Histogram(
                processor: processor,
                resource: resource,
                label: label,
                dimensions: dimensions
            )
        } else {
            return Gauge(
                processor: processor,
                resource: resource,
                label: label,
                dimensions: dimensions
            )
        }
    }

    func makeTimer(label: String, dimensions: [(String, String)]) -> TimerHandler {
        HistogramTimer(
            processor: processor,
            resource: resource,
            label: label,
            dimensions: dimensions
        )
    }

    // NOOPs
    func destroyCounter(_ handler: CounterHandler) { }
    func destroyRecorder(_ handler: RecorderHandler) { }
    func destroyTimer(_ handler: TimerHandler) { }
}

extension OTel.MetricsFactory {
    final class Counter: CounterHandler {
        let processor: OTelMetricsProcessor
        let resource: OTel.Resource
        let label: String
        let dimensions: [(String, String)]
        
        init(processor: OTelMetricsProcessor, resource: OTel.Resource, label: String, dimensions: [(String, String)]) {
            self.processor = processor
            self.resource = resource
            self.label = label
            self.dimensions = dimensions
        }
        
        func reset() {}
        
        func increment(by amount: Int64) {
            processor.processMetric(
                .sum(
                    OTel.Sum(
                        resource: resource,
                        label: label,
                        dimensions: dimensions,
                        dataPoints: [
                            .int(amount)
                        ],
                        isCumulative: true,
                        isMonotonic: true
                    )
                )
            )
        }
    }
    
    final class Recorder: RecorderHandler {
        let processor: OTelMetricsProcessor
        let resource: OTel.Resource
        let label: String
        let dimensions: [(String, String)]
        
        init(processor: OTelMetricsProcessor, resource: OTel.Resource, label: String, dimensions: [(String, String)]) {
            self.processor = processor
            self.resource = resource
            self.label = label
            self.dimensions = dimensions
        }
        
        func record(_ value: Int64) {
            
        }
        
        func record(_ value: Double) {
            
        }
    }
    
    final class Gauge: RecorderHandler {
        let processor: OTelMetricsProcessor
        let resource: OTel.Resource
        let label: String
        let dimensions: [(String, String)]
        
        init(processor: OTelMetricsProcessor, resource: OTel.Resource, label: String, dimensions: [(String, String)]) {
            self.processor = processor
            self.resource = resource
            self.label = label
            self.dimensions = dimensions
        }
        
        func record(_ value: Int64) {
            let gauge = OTel.Gauge(
                resource: resource,
                label: label,
                dimensions: dimensions,
                dataPoints: [
                    .int(value)
                ]
            )
            
            processor.processMetric(.gauge(gauge))
        }
        
        func record(_ value: Double) {
            let gauge = OTel.Gauge(
                resource: resource,
                label: label,
                dimensions: dimensions,
                dataPoints: [
                    .double(value)
                ]
            )
            
            processor.processMetric(.gauge(gauge))
        }
    }
    
    final class Histogram: RecorderHandler {
        let processor: OTelMetricsProcessor
        let resource: OTel.Resource
        let label: String
        var unit: TimeUnit?
        let dimensions: [(String, String)]

        init(processor: OTelMetricsProcessor, resource: OTel.Resource, label: String, dimensions: [(String, String)]) {
            self.processor = processor
            self.resource = resource
            self.label = label
            self.dimensions = dimensions
        }

        func record(_ value: Int64) {
            var now: timespec = .init()
            clock_gettime(CLOCK_REALTIME, &now)
            
            let histogram = OTel.Histogram(
                resource: resource,
                label: label,
                dimensions: dimensions,
                dataPoints: [
                    .init(
                        unixTimeNanoseconds: UInt64(now.tv_nsec),
                        value: .int(value)
                    )
                ]
            )
            
            processor.processMetric(.histogram(histogram))
        }
        
        func record(_ value: Double) {
            var now: timespec = .init()
            clock_gettime(CLOCK_REALTIME, &now)
            
            let histogram = OTel.Histogram(
                resource: resource,
                label: label,
                dimensions: dimensions,
                dataPoints: [
                    .init(
                        unixTimeNanoseconds: UInt64(now.tv_nsec),
                        value: .double(value)
                    )
                ]
            )
            
            processor.processMetric(.histogram(histogram))
        }
    }
    
    final class HistogramTimer: TimerHandler {
        let histogram: Histogram
        
        init(processor: OTelMetricsProcessor, resource: OTel.Resource, label: String, dimensions: [(String, String)]) {
            self.histogram = .init(
                processor: processor,
                resource: resource,
                label: label,
                dimensions: dimensions
            )
        }
        
        func recordNanoseconds(_ duration: Int64) {
            histogram.record(duration)
        }
    }
}
