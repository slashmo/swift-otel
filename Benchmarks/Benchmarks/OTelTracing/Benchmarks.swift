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
import Foundation

let benchmarks = {
    let ciMetrics: [BenchmarkMetric] = [
        .instructions,
        .mallocCountTotal,
    ]
    let localMetrics = BenchmarkMetric.default

    Benchmark.defaultConfiguration = .init(
        metrics: ProcessInfo.processInfo.environment["CI"] != nil ? ciMetrics : localMetrics,
        warmupIterations: 10
    )

    // MARK: - Benchmarks

    tracerBenchmarks()
    samplerBenchmarks()
}
