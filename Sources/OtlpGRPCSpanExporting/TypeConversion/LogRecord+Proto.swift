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

import struct Foundation.Data

extension Opentelemetry_Proto_Logs_V1_LogRecord {
    init(_ logRecord: OTel.LogRecord) {
        self = .with { record in
            record.body = Opentelemetry_Proto_Common_V1_AnyValue.with { body in
                body.stringValue = "\(logRecord.message)"
            }
            if let traceIDBytes = logRecord.traceIDBytes {
                record.traceID = Data(traceIDBytes)
            }
            if let spanIDBytes = logRecord.spanIDBytes {
                record.spanID = Data(spanIDBytes)
            }

            record.severityText = logRecord.logLevel.rawValue
            switch logRecord.logLevel {
            case .trace:
                record.severityNumber = .trace
            case .debug:
                record.severityNumber = .debug
            case .info:
                record.severityNumber = .info
            case .notice:
                // TODO: Check if .notice ==> .info2 makes sense
                record.severityNumber = .info2
            case .warning:
                record.severityNumber = .warn
            case .error:
                record.severityNumber = .error
            case .critical:
                // TODO: Check if .critical ==> .fatal makes sense
                record.severityNumber = .fatal
            }

            record.timeUnixNano = logRecord.timestamp.unixNanoseconds
            record.observedTimeUnixNano = logRecord.timestamp.unixNanoseconds

            if let metadata = logRecord.metadata {
                record.attributes = metadata.map { metadata in
                    .with { attribute in
                        attribute.key = metadata.key
                        attribute.value = .init(metadata.value)
                    }
                }
            }
        }
    }
}
