//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A metric exporter that ignores all operations, used when no metrics should be exported.
///
/// - TODO: Why are we providing this?
@_spi(Metrics)
public struct OTelNoOpMetricExporter: OTelMetricExporter {
    public init() {}
    public func export(_ batch: some Collection<OTelResourceMetrics>) async throws {}
    public func forceFlush() async throws {}
    public func shutdown() async {}
}
