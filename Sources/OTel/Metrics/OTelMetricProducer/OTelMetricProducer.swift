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

/// A bridge from third-party metric sources, so they can be plugged into an OpenTelemetry MetricReader as a source of
/// aggregated metric data.
///
/// - Seealso: [](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#metricproducer)
@_spi(Metrics)
public protocol OTelMetricProducer: Sendable {
    /// Provides metrics from the MetricProducer to the caller.
    ///
    /// - Returns: a batch of metric points.
    /// - Seealso: [](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#produce-batch)
    /// - TODO: Consider adding metrics filter parameter (experimental in OTel 1.29.0)
    func produce() -> [OTelMetricPoint]
}
