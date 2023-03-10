//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIO

extension OTel {
    public struct SimpleLogRecordProcessor: OTelLogRecordProcessor {
        private let exporter: any OTelLogRecordExporter

        public init(exportingTo exporter: any OTelLogRecordExporter) {
            self.exporter = exporter
        }

        public func processLogRecord(_ logRecord: OTel.LogRecord) {
            _ = exporter.export([logRecord])
        }

        public func shutdownGracefully() -> EventLoopFuture<Void> {
            exporter.shutdownGracefully()
        }
    }
}
