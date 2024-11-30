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

import Benchmark
@_spi(OTelBenchmarking) import OTel
import ServiceContextModule
import W3CTraceContext

func tracerBenchmarks() {
    Benchmark("Starting sampled root spans") { benchmark in
        let tracer = OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelConstantSampler(isOn: true),
            propagator: OTelW3CPropagator(),
            processor: OTelNoOpSpanProcessor(),
            environment: [:],
            resource: OTelResource()
        )

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(tracer.startSpan("test"))
        }
    }

    Benchmark("Starting sampled child spans") { benchmark in
        let tracer = OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelConstantSampler(isOn: true),
            propagator: OTelW3CPropagator(),
            processor: OTelNoOpSpanProcessor(),
            environment: [:],
            resource: OTelResource()
        )

        let parentSpanContext = OTelSpanContext.local(
            traceID: .random(),
            spanID: .random(),
            parentSpanID: nil,
            traceFlags: .sampled,
            traceState: TraceState()
        )
        let parentContext = ServiceContext.withSpanContext(parentSpanContext)

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(tracer.startSpan("test", context: parentContext))
        }
    }

    Benchmark("Starting dropped root spans") { benchmark in
        let tracer = OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelConstantSampler(isOn: false),
            propagator: OTelW3CPropagator(),
            processor: OTelNoOpSpanProcessor(),
            environment: [:],
            resource: OTelResource()
        )

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(tracer.startSpan("test"))
        }
    }
}
