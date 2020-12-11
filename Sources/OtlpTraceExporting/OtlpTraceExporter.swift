//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2020 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import GRPC
import NIO
import OpenTelemetry
import Tracing
import W3CTraceContext

public final class OtlpTraceExporter: OpenTelemetryTraceExporter {
    private let client: Opentelemetry_Proto_Collector_Trace_V1_TraceServiceClient

    public init(channel: GRPCChannel) {
        self.client = .init(channel: channel)
    }

    public func export(spans: [OpenTelemetrySpan]) -> EventLoopFuture<Void> {
        let protoSpans = spans.compactMap { span -> Opentelemetry_Proto_Trace_V1_Span? in
            guard let traceContext = span.baggage.traceContext else { return nil }
            var protoSpan = Opentelemetry_Proto_Trace_V1_Span()
            protoSpan.name = span.name
            protoSpan.kind = .init(span.kind)
            protoSpan.traceID = traceContext.parent.traceID.data()
            if let spanIDData = traceContext.parent.parentIDData() {
                protoSpan.spanID = spanIDData
            }
            if let parentIDData = (span.links.first?.baggage.traceContext?.parent).flatMap({ $0.parentIDData() }) {
                protoSpan.parentSpanID = parentIDData
            }
            protoSpan.status = .init(span.status)
            protoSpan.startTimeUnixNano = span.startTime.unixNanoseconds
            protoSpan.endTimeUnixNano = span.endTime!.unixNanoseconds
            protoSpan.attributes = .init(span.attributes)

            protoSpan.events = span.events.map { spanEvent in
                Opentelemetry_Proto_Trace_V1_Span.Event.with { event in
                    event.name = .init(spanEvent.name)
                    event.timeUnixNano = spanEvent.time.rawValue
                    event.attributes = .init(spanEvent.attributes)
                }
            }
            return protoSpan
        }

        let request = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with { request in
            request.resourceSpans = [Opentelemetry_Proto_Trace_V1_ResourceSpans.with { resourceSpans in
                resourceSpans.resource = .with { resource in
                    resource.attributes = .init([
                        "telemetry.sdk.name": "opentelemetry",
                        "telemetry.sdk.language": "swift",
                        "telemetry.sdk.version": "0.1.0",
                        // TODO: - Make Service Configurable
                        "service.name": "shoppingcart",
                        "service.namespace": "Shop",
                        "service.instance.id": "627cc493-f310-47de-96bd-71410b7dec09",
                        "service.version": "2.0.0",
                    ])
                }
                resourceSpans.instrumentationLibrarySpans = [Opentelemetry_Proto_Trace_V1_InstrumentationLibrarySpans.with { instrumentationLibrarySpans in
                    instrumentationLibrarySpans.instrumentationLibrary = Opentelemetry_Proto_Common_V1_InstrumentationLibrary.with { library in
                        library.name = "opentelemetry-swift"
                        library.version = "0.1.0"
                    }
                    instrumentationLibrarySpans.spans = protoSpans
                }]
            }]
        }
        self.client.defaultCallOptions.timeLimit = .timeout(.milliseconds(100))
        let export = self.client.export(request)
        return export.response.map { _ in print("Exported \(spans.compactMap(\.baggage.traceContext?.parent))") }
    }
}

extension Array where Element == Opentelemetry_Proto_Common_V1_KeyValue {
    init(_ attributes: SpanAttributes) {
        self.init()
        attributes.forEach { key, attribute in
            self.append(Opentelemetry_Proto_Common_V1_KeyValue.with { keyValue in
                keyValue.key = key
                keyValue.value = .init(attribute)
            })
        }
    }
}

extension Opentelemetry_Proto_Trace_V1_Span.SpanKind {
    init(_ spanKind: SpanKind) {
        switch spanKind {
        case .server:
            self = .server
        case .client:
            self = .client
        case .producer:
            self = .producer
        case .consumer:
            self = .consumer
        case .internal:
            self = .internal
        }
    }
}

extension Opentelemetry_Proto_Trace_V1_Status {
    init(_ spanStatus: SpanStatus) {
        self = Opentelemetry_Proto_Trace_V1_Status.with { status in
            if let message = spanStatus.message {
                status.message = message
            }
            switch spanStatus.canonicalCode {
            case .aborted:
                status.deprecatedCode = .aborted
            case .alreadyExists:
                status.deprecatedCode = .alreadyExists
            case .ok:
                status.code = .ok
            case .cancelled:
                status.deprecatedCode = .cancelled
            case .unknown:
                status.code = .unset
            case .invalidArgument:
                status.deprecatedCode = .invalidArgument
            case .deadlineExceeded:
                status.deprecatedCode = .deadlineExceeded
            case .notFound:
                status.deprecatedCode = .notFound
            case .permissionDenied:
                status.deprecatedCode = .permissionDenied
            case .resourceExhausted:
                status.deprecatedCode = .resourceExhausted
            case .failedPrecondition:
                status.deprecatedCode = .failedPrecondition
            case .outOfRange:
                status.deprecatedCode = .outOfRange
            case .unimplemented:
                status.deprecatedCode = .unimplemented
            case .internal:
                status.deprecatedCode = .internalError
            case .unavailable:
                status.deprecatedCode = .unavailable
            case .dataLoss:
                status.deprecatedCode = .dataLoss
            case .unauthenticated:
                status.deprecatedCode = .unauthenticated
            }
        }
    }
}

extension W3CTraceContext.TraceID {
    func data() -> Data {
        let highBytes = withUnsafeBytes(of: self.high.bigEndian, [UInt8].init)
        let lowBytes = withUnsafeBytes(of: self.low.bigEndian, [UInt8].init)
        return Data(highBytes + lowBytes)
    }
}

extension W3CTraceContext.TraceParent {
    func parentIDData() -> Data? {
        guard let parentID = UInt64(self.parentID, radix: 16) else { return nil }
        return Data(withUnsafeBytes(of: parentID, [UInt8].init))
    }
}

extension DispatchWallTime {
    var unixNanoseconds: UInt64 {
        UInt64(-Int64(bitPattern: self.rawValue))
    }
}

extension Opentelemetry_Proto_Common_V1_AnyValue {
    init(_ attribute: SpanAttribute) {
        self = .with { value in
            switch attribute {
            case .bool(let bool):
                value.boolValue = bool
            case .int(let int):
                value.intValue = int
            case .double(let double):
                value.doubleValue = double
            case .string(let string):
                value.stringValue = string
            case .stringConvertible(let stringConvertible):
                value.stringValue = String(describing: stringConvertible)
            case .boolArray(let boolArray):
                value.arrayValue = .init(boolArray, transform: SpanAttribute.bool)
            case .intArray(let intArray):
                value.arrayValue = .init(intArray, transform: SpanAttribute.int)
            case .doubleArray(let doubleArray):
                value.arrayValue = .init(doubleArray, transform: SpanAttribute.double)
            case .stringArray(let stringArray):
                value.arrayValue = .init(stringArray, transform: SpanAttribute.string)
            case .stringConvertibleArray(let stringConvertibleArray):
                value.arrayValue = .init(stringConvertibleArray, transform: SpanAttribute.stringConvertible)
            }
        }
    }
}

extension Opentelemetry_Proto_Common_V1_ArrayValue {
    init<T>(_ array: [T], transform: (T) -> SpanAttribute) {
        self = .with { a in
            a.values = array.map { .init(transform($0)) }
        }
    }
}
