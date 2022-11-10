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

import OpenTelemetry
import Logging

extension Opentelemetry_Proto_Logs_V1_ScopeLogs {
    init(logs: [OTel.RecordedLog]) {
        self.logRecords = logs.map(Opentelemetry_Proto_Logs_V1_LogRecord.init)
    }
}

extension Opentelemetry_Proto_Logs_V1_LogRecord {
    init(_ resource: OTel.RecordedLog) {
        timeUnixNano = resource.unixTimeNanoseconds
        observedTimeUnixNano = resource.unixTimeNanoseconds
        severityNumber = resource.level.severityNumber
        severityText = resource.level.severityText
        
        if let metadata = resource.metadata {
            attributes = .init(metadata)
        }
        
        // TODO: Do we set the `spanID` and `traceID`?
    }
}

extension Array where Element == Opentelemetry_Proto_Common_V1_KeyValue {
    init(_ metadata: Logger.Metadata) {
        self = metadata.map { (key, value) in
            var keyValue = Opentelemetry_Proto_Common_V1_KeyValue()
            keyValue.key = key
            keyValue.value = .init(value)
            return keyValue
        }
    }
}

extension Opentelemetry_Proto_Common_V1_KeyValueList {
    init(_ metadata: Logger.Metadata) {
        values = .init(metadata)
    }
}

extension Opentelemetry_Proto_Common_V1_ArrayValue {
    init(_ array: [Logger.MetadataValue]) {
        self.values = array.map { value in
            Opentelemetry_Proto_Common_V1_AnyValue(value)
        }
    }
}

extension Opentelemetry_Proto_Common_V1_AnyValue {
    init(_ value: Logger.MetadataValue) {
        switch value {
        case .string(let string):
            self.stringValue = string
        case .stringConvertible(let stringConvertible):
            self.stringValue = stringConvertible.description
        case .dictionary(let metadata):
            self.kvlistValue = .init(metadata)
        case .array(let array):
            self.arrayValue = .init(array)
        }
    }
}

extension Logger.Level {
    var severityNumber: Opentelemetry_Proto_Logs_V1_SeverityNumber {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .info
        case .warning:
            return .warn
        case .error:
            return .error
        case .critical:
            return .fatal
        }
    }
    
    var severityText: String {
        switch self {
        case .trace:
            return "trace"
        case .debug:
            return "debug"
        case .info:
            return "info"
        case .notice:
            return "notice"
        case .warning:
            return "warning"
        case .error:
            return "error"
        case .critical:
            return "critical"
        }
    }
}
