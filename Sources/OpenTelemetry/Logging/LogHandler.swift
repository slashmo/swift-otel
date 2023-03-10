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

import InstrumentationBaggage
import Logging

public struct OTelLogHandler: LogHandler {
    public var logLevel: Logger.Level = .info

    public var metadata = Logger.Metadata()
    public var metadataProvider: Logger.MetadataProvider?

    private let label: String
    private let processor: any OTelLogRecordProcessor

    public init(
        label: String,
        processor: any OTelLogRecordProcessor,
        metadataProvider: Logger.MetadataProvider? = LoggingSystem.metadataProvider
    ) {
        self.label = label
        self.processor = processor
        self.metadataProvider = metadataProvider
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set {
            metadata[metadataKey] = newValue
        }
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        var effectiveMetadata = Self.effectiveMetadata(
            base: self.metadata,
            provider: metadataProvider,
            explicit: metadata
        )

        let traceIDBytes: [UInt8]?
        let spanIDBytes: [UInt8]?

        if let traceIDMetadata = effectiveMetadata?["trace_id"],
           let spanIDMetadata = effectiveMetadata?["span_id"]
        {
            switch traceIDMetadata {
            case .stringConvertible(let stringConvertible):
                traceIDBytes = (stringConvertible as? OTel.TraceID)?.bytes
                // remove trace ID from metadata because it's already reported as a separate field
                effectiveMetadata?.removeValue(forKey: "trace_id")
            case .string:
                // TODO: parse string value
                fallthrough
            default:
                traceIDBytes = nil
            }

            switch spanIDMetadata {
            case .stringConvertible(let stringConvertible):
                spanIDBytes = (stringConvertible as? OTel.SpanID)?.bytes
                // remove span ID from metadata because it's already reported as a separate field
                effectiveMetadata?.removeValue(forKey: "span_id")
            case .string:
                // TODO: parse string value
                fallthrough
            default:
                spanIDBytes = nil
            }
        } else {
            traceIDBytes = nil
            spanIDBytes = nil
        }

        let logRecord = OTel.LogRecord(
            logLevel: level,
            timestamp: .now(),
            message: message,
            metadata: effectiveMetadata,
            traceIDBytes: traceIDBytes,
            spanIDBytes: spanIDBytes
        )

        processor.processLogRecord(logRecord)
    }

    private static func effectiveMetadata(
        base: Logger.Metadata,
        provider: Logger.MetadataProvider?,
        explicit: Logger.Metadata?
    ) -> Logger.Metadata? {
        var metadata = base

        let provided = provider?.get() ?? [:]

        if provided.isEmpty, (explicit ?? [:]).isEmpty {
            return metadata
        }

        if !provided.isEmpty {
            metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
        }

        if let explicit, !explicit.isEmpty {
            metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
        }

        return metadata
    }
}
