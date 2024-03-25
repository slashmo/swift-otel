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

import ServiceLifecycle
import ServiceContextModule

/// Log processors allow for processing logs throughout their lifetime via ``onStart(_:parentContext:)`` and ``onEnd(_:)`` calls.
/// Usually, log processors will forward logs to a configurable ``OTelLogExporter``.
///
/// [OpenTelemetry specification: LogRecord processor](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/logs/sdk.md#logrecordprocessor)
///
/// ### Implementation Notes
///
/// On shutdown, processors forwarding logs to an ``OTelLogExporter`` MUST shutdown that exporter.
@_spi(Logging)
public protocol OTelLogProcessor: Service & Sendable {
    func onLog(_ log: OTelLog)

    /// Force log processors that batch logs to flush immediately.
    func forceFlush() async throws
}
