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

@testable import OpenTelemetry
@testable import OtlpGRPCSpanExporting
import Tracing
import XCTest

final class TypeConversionTests: XCTestCase {
    // MARK: - Export Request

    func test_convertToExportRequest() throws {
        let startTime: UInt64 = 42
        let endTime: UInt64 = 84

        let resource = OTel.Resource(attributes: ["id": "1"])

        let span1 = OTel.RecordedSpan(
            operationName: #function,
            kind: .internal,
            status: nil,
            context: OTel.SpanContext(
                traceID: .init(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
                spanID: .init(bytes: (1, 2, 3, 4, 5, 6, 7, 8)),
                traceFlags: .sampled,
                isRemote: false
            ),
            baggage: .topLevel,
            startTime: startTime,
            endTime: endTime,
            attributes: [:],
            events: [],
            links: [],
            resource: resource
        )
        let span2 = OTel.RecordedSpan(
            operationName: #function,
            kind: .internal,
            status: nil,
            context: OTel.SpanContext(
                traceID: .init(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
                spanID: .init(bytes: (1, 2, 3, 4, 5, 6, 7, 8)),
                traceFlags: .sampled,
                isRemote: false
            ),
            baggage: .topLevel,
            startTime: startTime,
            endTime: endTime,
            attributes: [:],
            events: [],
            links: [],
            resource: resource
        )

        let request = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest([span1, span2])

        XCTAssertEqual(request.resourceSpans.count, 1)
        let resourceSpans = try XCTUnwrap(request.resourceSpans.first)
        XCTAssertEqual(resourceSpans.resource, .init(resource))
        XCTAssertEqual(resourceSpans.instrumentationLibrarySpans, [.init(spans: [span1, span2])])
    }

    // MARK: - Instrumentation Library Spans

    func test_convertInstrumentationLibrarySpans() {
        let startTime: UInt64 = 42
        let endTime: UInt64 = 84

        let resource = OTel.Resource(attributes: ["key": "value"])
        let span = OTel.RecordedSpan(
            operationName: #function,
            kind: .internal,
            status: nil,
            context: OTel.SpanContext(
                traceID: .init(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
                spanID: .init(bytes: (1, 2, 3, 4, 5, 6, 7, 8)),
                traceFlags: .sampled,
                isRemote: false
            ),
            baggage: .topLevel,
            startTime: startTime,
            endTime: endTime,
            attributes: [:],
            events: [],
            links: [],
            resource: resource
        )

        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_InstrumentationLibrarySpans(spans: [span]),
            .with {
                $0.instrumentationLibrary = .with { library in
                    library.name = "swift-otel"
                    library.version = OTel.versionString
                }
                $0.spans = [.init(span)]
            }
        )
    }

    // MARK: - Span

    func test_convertSpan() {
        let startTime: UInt64 = 42
        let eventStartTime: UInt64 = 63
        let endTime: UInt64 = 84

        let span = OTel.RecordedSpan(
            operationName: "test",
            kind: .server,
            status: .init(code: .ok),
            context: .init(
                traceID: .init(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
                spanID: .init(bytes: (1, 2, 3, 4, 5, 6, 7, 8)),
                parentSpanID: .init(bytes: (9, 10, 11, 12, 13, 14, 15, 16)),
                traceFlags: .sampled,
                traceState: .init([("vendor", "value")]),
                isRemote: false
            ),
            baggage: .topLevel,
            startTime: startTime,
            endTime: endTime,
            attributes: ["key": "value"],
            events: [
                SpanEvent(name: "test", clock: TracerClockMock(now: .init(nanosecondsSinceEpoch: eventStartTime)))
            ],
            // will be filtered out due to missing span context
            links: [SpanLink(baggage: .topLevel, attributes: [:])],
            resource: OTel.Resource()
        )
        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_Span(span),
            .with {
                $0.name = "test"
                $0.startTimeUnixNano = startTime
                $0.endTimeUnixNano = endTime
                $0.kind = .server
                $0.status = .init(.init(code: .ok))
                $0.traceID = Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
                $0.spanID = Data([1, 2, 3, 4, 5, 6, 7, 8])
                $0.parentSpanID = Data([9, 10, 11, 12, 13, 14, 15, 16])
                $0.traceState = "vendor=value"
                $0.attributes = .init(["key": "value"])
                $0.events = [.init(SpanEvent(
                    name: "test",
                    clock: TracerClockMock(now: .init(nanosecondsSinceEpoch: eventStartTime))
                ))]
            }
        )
    }

    // MARK: - SpanKind

    func test_convertSpanKind_internal() {
        XCTAssertEqual(Opentelemetry_Proto_Trace_V1_Span.SpanKind(.internal), .internal)
    }

    func test_convertSpanKind_server() {
        XCTAssertEqual(Opentelemetry_Proto_Trace_V1_Span.SpanKind(.server), .server)
    }

    func test_convertSpanKind_client() {
        XCTAssertEqual(Opentelemetry_Proto_Trace_V1_Span.SpanKind(.client), .client)
    }

    func test_convertSpanKind_producer() {
        XCTAssertEqual(Opentelemetry_Proto_Trace_V1_Span.SpanKind(.producer), .producer)
    }

    func test_convertSpanKind_consumer() {
        XCTAssertEqual(Opentelemetry_Proto_Trace_V1_Span.SpanKind(.consumer), .consumer)
    }

    // MARK: - SpanStatus

    func test_convertSpanStatus_ok() {
        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_Status(.init(code: .ok)),
            .with { $0.code = .ok }
        )
    }

    func test_convertSpanStatus_okWithMessage() {
        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_Status(.init(code: .ok, message: "test")),
            .with {
                $0.code = .ok
                $0.message = "test"
            }
        )
    }

    func test_convertSpanStatus_error() {
        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_Status(.init(code: .error)),
            .with { $0.code = .error }
        )
    }

    func test_convertSpanStatus_errorWithMessage() {
        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_Status(.init(code: .error, message: "test")),
            .with {
                $0.code = .error
                $0.message = "test"
            }
        )
    }

    // MARK: - SpanAttributes

    func test_convertSpanAttribute_string() {
        XCTAssertEqual(Opentelemetry_Proto_Common_V1_AnyValue(.string("test")), .with { $0.stringValue = "test" })
    }

    func test_convertSpanAttribute_stringArray() {
        XCTAssertEqual(
            Opentelemetry_Proto_Common_V1_AnyValue(.stringArray(["1", "2"])),
            .with { value in
                value.arrayValue = .with {
                    $0.values = [
                        .with { v in v.stringValue = "1" },
                        .with { v in v.stringValue = "2" },
                    ]
                }
            }
        )
    }

    func test_convertSpanAttribute_stringConvertible() {
        XCTAssertEqual(Opentelemetry_Proto_Common_V1_AnyValue(.stringConvertible(42)), .with { $0.stringValue = "42" })
    }

    func test_convertSpanAttribute_stringConvertibleArray() {
        XCTAssertEqual(
            Opentelemetry_Proto_Common_V1_AnyValue(.stringConvertibleArray([1, 2])),
            .with { value in
                value.arrayValue = .with {
                    $0.values = [
                        .with { v in v.stringValue = "1" },
                        .with { v in v.stringValue = "2" },
                    ]
                }
            }
        )
    }

    func test_convertSpanAttribute_int() {
        XCTAssertEqual(Opentelemetry_Proto_Common_V1_AnyValue(.int(42)), .with { $0.intValue = 42 })
    }

    func test_convertSpanAttribute_int32Array() {
        XCTAssertEqual(
            Opentelemetry_Proto_Common_V1_AnyValue(.int32Array([1, 2])),
            .with { value in
                value.arrayValue = .with {
                    $0.values = [
                        .with { v in v.intValue = 1 },
                        .with { v in v.intValue = 2 },
                    ]
                }
            }
        )
    }

    func test_convertSpanAttribute_int64Array() {
        XCTAssertEqual(
            Opentelemetry_Proto_Common_V1_AnyValue(.int64Array([1, 2])),
            .with { value in
                value.arrayValue = .with {
                    $0.values = [
                        .with { v in v.intValue = 1 },
                        .with { v in v.intValue = 2 },
                    ]
                }
            }
        )
    }

    func test_convertSpanAttribute_double() {
        XCTAssertEqual(Opentelemetry_Proto_Common_V1_AnyValue(.double(42.0)), .with { $0.doubleValue = 42.0 })
    }

    func test_convertSpanAttribute_doubleArray() {
        XCTAssertEqual(
            Opentelemetry_Proto_Common_V1_AnyValue(.doubleArray([1.2, 2.3])),
            .with { value in
                value.arrayValue = .with {
                    $0.values = [
                        .with { v in v.doubleValue = 1.2 },
                        .with { v in v.doubleValue = 2.3 },
                    ]
                }
            }
        )
    }

    func test_convertSpanAttribute_bool() {
        XCTAssertEqual(Opentelemetry_Proto_Common_V1_AnyValue(.bool(true)), .with { $0.boolValue = true })
    }

    func test_convertSpanAttribute_boolArray() {
        XCTAssertEqual(
            Opentelemetry_Proto_Common_V1_AnyValue(.boolArray([true, false])),
            .with { value in
                value.arrayValue = .with {
                    $0.values = [
                        .with { v in v.boolValue = true },
                        .with { v in v.boolValue = false },
                    ]
                }
            }
        )
    }

    func test_convertSpanAttributes() {
        XCTAssertEqual(
            [Opentelemetry_Proto_Common_V1_KeyValue]([
                "meaningOfLife": .int(42),
            ]),
            [
                .with {
                    $0.key = "meaningOfLife"
                    $0.value = .with { v in v.intValue = 42 }
                },
            ]
        )
    }

    // MARK: - Resource

    func test_convertResource() {
        XCTAssertEqual(
            Opentelemetry_Proto_Resource_V1_Resource(OTel.Resource()),
            .with { $0.attributes = [] }
        )
    }

    func test_convertResource_withAttributes() {
        XCTAssertEqual(
            Opentelemetry_Proto_Resource_V1_Resource(OTel.Resource(attributes: ["key": "value"])),
            .with { $0.attributes = [
                .with { kv in
                    kv.key = "key"
                    kv.value = .with { v in v.stringValue = "value" }
                },
            ] }
        )
    }

    // MARK: - SpanEvent

    func test_convertSpanEvent() {
        let clock = TracerClockMock(now: .init(nanosecondsSinceEpoch: 42))
        let event = SpanEvent(name: "test", clock: clock)

        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_Span.Event(event),
            .with {
                $0.name = "test"
                $0.timeUnixNano = 42
            }
        )
    }

    func test_convertSpanEvent_withAttributes() {
        let clock = TracerClockMock(now: .init(nanosecondsSinceEpoch: 42))
        let event = SpanEvent(name: "test", clock: clock, attributes: ["key": "value"])

        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_Span.Event(event),
            .with {
                $0.name = "test"
                $0.timeUnixNano = 42
                $0.attributes = [
                    .with { kv in
                        kv.key = "key"
                        kv.value = .with { v in v.stringValue = "value" }
                    },
                ]
            }
        )
    }

    // MARK: - SpanLink

    func test_convertSpanLink() {
        var baggage = Baggage.topLevel
        baggage.spanContext = OTel.SpanContext(
            traceID: OTel.TraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
            spanID: OTel.SpanID(bytes: (1, 2, 3, 4, 5, 6, 7, 8)),
            traceFlags: .sampled,
            traceState: OTel.TraceState([(vendor: "test", value: "test")]),
            isRemote: false
        )

        let link = SpanLink(baggage: baggage, attributes: [:])

        XCTAssertEqual(
            Opentelemetry_Proto_Trace_V1_Span.Link(link),
            .with { protoLink in
                protoLink.traceID = Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
                protoLink.spanID = Data([1, 2, 3, 4, 5, 6, 7, 8])
                protoLink.traceState = "test=test"
            }
        )
    }

    func test_convertSpanLink_withoutSpanContext() {
        XCTAssertNil(Opentelemetry_Proto_Trace_V1_Span.Link(SpanLink(baggage: .topLevel, attributes: [:])))
    }
}

private struct TracerClockMock: TracerClock {
    let now: Instant

    struct Instant: TracerInstant {
        let nanosecondsSinceEpoch: UInt64

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.nanosecondsSinceEpoch < rhs.nanosecondsSinceEpoch
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.nanosecondsSinceEpoch == rhs.nanosecondsSinceEpoch
        }
    }
}
