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
import XCTest

final class W3CPropagatorTests: XCTestCase {
    private let propagator = OTel.W3CPropagator()
    private let injector = DictionaryInjector()
    private let extractor = DictionaryExtractor()

    // MARK: - Inject

    func test_injectsTraceparentHeader_notSampled() {
        let spanContext = OTel.SpanContext(
            traceID: .stub,
            spanID: .stub,
            parentSpanID: .stub,
            traceFlags: [],
            traceState: nil,
            isRemote: false
        )
        var headers = [String: String]()

        propagator.inject(spanContext, into: &headers, using: injector)

        XCTAssertEqual(headers, ["traceparent": "00-0102030405060708090a0b0c0d0e0f10-0102030405060708-00"])
    }

    func test_injectsTraceparentHeader_sampled() {
        let spanContext = OTel.SpanContext(
            traceID: .stub,
            spanID: .stub,
            parentSpanID: .stub,
            traceFlags: .sampled,
            traceState: nil,
            isRemote: false
        )
        var headers = [String: String]()

        propagator.inject(spanContext, into: &headers, using: self.injector)

        XCTAssertEqual(headers, ["traceparent": "00-0102030405060708090a0b0c0d0e0f10-0102030405060708-01"])
    }

    func test_injectsTraceparentAndTracestateHeaders() {
        let spanContext = OTel.SpanContext(
            traceID: .stub,
            spanID: .stub,
            parentSpanID: .stub,
            traceFlags: .sampled,
            traceState: OTel.TraceState([(vendor: "test1", value: "123"), (vendor: "test2", value: "abc")]),
            isRemote: false
        )
        var headers = [String: String]()

        propagator.inject(spanContext, into: &headers, using: self.injector)

        XCTAssertEqual(headers["traceparent"], "00-0102030405060708090a0b0c0d0e0f10-0102030405060708-01")
        XCTAssertEqual(headers["tracestate"], "test1=123,test2=abc")
    }

    // MARK: - Extract

    func test_extractsNil_withoutW3CHeaders() throws {
        let headers = ["Content-Type": "application/json"]

        XCTAssertNil(try propagator.extractSpanContext(from: headers, using: self.extractor))
    }

    func test_extractsNil_withoutTraceparentHeader() throws {
        let headers = ["tracestate": "test1=123,test2=abc"]

        XCTAssertNil(try propagator.extractSpanContext(from: headers, using: self.extractor))
    }

    func test_extractsTraceparentHeader_notSampled() throws {
        let headers = ["traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-00"]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: self.extractor))

        XCTAssertEqual(String(describing: spanContext.traceID), "0af7651916cd43dd8448eb211c80319c")
        XCTAssertEqual(String(describing: spanContext.spanID), "b7ad6b7169203331")
        XCTAssertTrue(spanContext.traceFlags.isEmpty)
        XCTAssertNil(spanContext.traceState)
    }

    func test_extractsTraceparentHeader_sampled() throws {
        let headers = ["traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01"]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: self.extractor))

        XCTAssertEqual(String(describing: spanContext.traceID), "0af7651916cd43dd8448eb211c80319c")
        XCTAssertEqual(String(describing: spanContext.spanID), "b7ad6b7169203331")
        XCTAssertEqual(spanContext.traceFlags, .sampled)
        XCTAssertNil(spanContext.traceState)
    }

    func test_extractsTraceparentAndTracestateHeader() throws {
        let headers = [
            "traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            "tracestate": "test1=123,test2=abc",
        ]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: self.extractor))

        XCTAssertEqual(String(describing: spanContext.traceID), "0af7651916cd43dd8448eb211c80319c")
        XCTAssertEqual(String(describing: spanContext.spanID), "b7ad6b7169203331")
        XCTAssertEqual(spanContext.traceFlags, .sampled)
        XCTAssertEqual(
            spanContext.traceState,
            OTel.TraceState([(vendor: "test1", value: "123"), (vendor: "test2", value: "abc")])
        )
    }

    func test_extractSupportsTracestateMultiTenantNotation() throws {
        let headers = [
            "traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            "tracestate": "customer1@test=123,customer2@test=abc",
        ]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: self.extractor))

        XCTAssertEqual(
            spanContext.traceState,
            OTel.TraceState([(vendor: "customer1@test", value: "123"), (vendor: "customer2@test", value: "abc")])
        )
    }

    func test_extractDiscardsEmptyTracestateHeader() throws {
        let headers = [
            "traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            "tracestate": "",
        ]
        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: self.extractor))

        XCTAssertNil(spanContext.traceState)
    }

    func test_extractFails_TraceparentInvalidLength() throws {
        let headers = ["traceparent": "test"]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: self.extractor),
            OTel.W3CPropagator.TraceParentParsingError(value: "test", reason: .invalidLength(4))
        )
    }

    func test_extractFails_TraceparentUnsupportedVersion() throws {
        let traceparent = "01-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01"
        let headers = ["traceparent": traceparent]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: self.extractor),
            OTel.W3CPropagator.TraceParentParsingError(value: traceparent, reason: .unsupportedVersion("01"))
        )
    }

    func test_extractFails_TraceparentInvalidDelimiters() throws {
        let traceparent = "00*0af7651916cd43dd8448eb211c80319c_b7ad6b7169203331+01"
        let headers = ["traceparent": traceparent]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: self.extractor),
            OTel.W3CPropagator.TraceParentParsingError(value: traceparent, reason: .invalidDelimiters)
        )
    }

    func test_extractFails_TraceStateVendorInvalidCharacter() throws {
        let tracestate = "🏝=test"
        let headers = [
            "traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            "tracestate": tracestate,
        ]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: self.extractor),
            OTel.W3CPropagator.TraceStateParsingError(value: tracestate, reason: .invalidCharacter("🏝"))
        )
    }

    func test_extractFails_TraceStateMissingValue() throws {
        let tracestate = "test"
        let headers = [
            "traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            "tracestate": tracestate,
        ]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: self.extractor),
            OTel.W3CPropagator.TraceStateParsingError(value: tracestate, reason: .missingValue(vendor: "test"))
        )
    }

    func test_extractFails_TraceStateInvalidCharacter_EqualSign() throws {
        let traceState = "test=123="

        let headers = [
            "traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            "tracestate": traceState,
        ]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: self.extractor),
            OTel.W3CPropagator.TraceStateParsingError(value: traceState, reason: .invalidCharacter("="))
        )
    }

    func test_extractFails_TraceStateInvalidCharacter_Emoji() throws {
        let traceState = "test=🏎"

        let headers = [
            "traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            "tracestate": traceState,
        ]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: self.extractor),
            OTel.W3CPropagator.TraceStateParsingError(value: traceState, reason: .invalidCharacter("🏎"))
        )
    }

    // MARK: - End To End

    func test_injectExtractedSpanContext() throws {
        let headers = [
            "traceparent": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            "tracestate": "key=value"
        ]

        let extractedSpanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: extractor))

        var injectedHeaders = [String: String]()

        propagator.inject(extractedSpanContext, into: &injectedHeaders, using: injector)

        XCTAssertEqual(injectedHeaders["traceparent"], headers["traceparent"])
        XCTAssertEqual(headers["tracestate"], headers["tracestate"])
    }
}
