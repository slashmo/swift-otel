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
        fatalError()
    }

    func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> RecorderHandler {
        fatalError()
    }

    func makeTimer(label: String, dimensions: [(String, String)]) -> TimerHandler {
        Timer(
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
    final class Timer: TimerHandler {
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

        func preferDisplayUnit(_ unit: TimeUnit) {
//            fatalError()
        }

        func recordNanoseconds(_ duration: Int64) {
//            let metric = OTel.RecordedMetric.sum(
//                resource: resource,
//                label: label
//            )
//
//            processor.processMetric(metric)
        }
    }
}
