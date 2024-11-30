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
import W3CTraceContext

func samplerBenchmarks() {
    Benchmark("Trace-id ratio based sampling result") { benchmark in

        let sampler = OTelTraceIDRatioBasedSampler(ratio: 0.5)

        // we generate the trace ids upfront to avoid measuring the generation time
        let traceIds = benchmark.scaledIterations.map { _ in TraceID.random() }

        benchmark.startMeasurement()

        for traceId in traceIds {
            blackHole(
                sampler.samplingResult(
                    operationName: "some-op",
                    kind: .internal,
                    traceID: traceId,
                    attributes: [:],
                    links: [],
                    parentContext: .topLevel
                )
            )
        }

        benchmark.stopMeasurement()
    }
}
