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

import OpenTelemetry
import XCTest
import class Foundation.ProcessInfo

final class OTelEnvironmentTests: XCTestCase {
    // MARK: - detected

    func test_detected_picksUpEnvironmentValuesFromSystem() {
        let environment = OTelEnvironment.detected()
        let keyValuePairs = ProcessInfo.processInfo.environment

        XCTAssertEqual(environment.values.count, keyValuePairs.count)
        for (key, value) in keyValuePairs {
            XCTAssertEqual(environment.values[key.uppercased()], value)
        }
    }

    // MARK: - headersFromValueForKey

    func test_headersFromValueForKey_missingKey_returnsNil() throws {
        let environment = OTelEnvironment(values: [:])

        XCTAssertNil(try environment.headers(fromValueForKey: "HEADERS"))
    }

    func test_headersFromValueForKey_singleHeader() throws {
        let environment: OTelEnvironment = ["HEADERS": "key=value"]

        let headers = try XCTUnwrap(try environment.headers(fromValueForKey: "HEADERS"))
        XCTAssertEqual(headers.count, 1)
        let (key, value) = try XCTUnwrap(headers.first)
        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, "value")
    }

    func test_headersFromValueForKey_multipleHeaders() throws {
        let environment: OTelEnvironment = ["HEADERS": "key1=foo,key2=bar"]

        let headers = try XCTUnwrap(try environment.headers(fromValueForKey: "HEADERS"))
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers[0].key, "key1")
        XCTAssertEqual(headers[0].value, "foo")
        XCTAssertEqual(headers[1].key, "key2")
        XCTAssertEqual(headers[1].value, "bar")
    }

    func test_headersFromValueForKey_multipleHeadersWithSameKey() throws {
        let environment: OTelEnvironment = ["HEADERS": "key=value1,key=value2"]

        let headers = try XCTUnwrap(try environment.headers(fromValueForKey: "HEADERS"))
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers[0].key, "key")
        XCTAssertEqual(headers[0].value, "value1")
        XCTAssertEqual(headers[1].key, "key")
        XCTAssertEqual(headers[1].value, "value2")
    }

    func test_headersFromValueForKey_stripsWhitespaceInKey() throws {
        let environment: OTelEnvironment = ["HEADERS": " key  =value"]

        let headers = try XCTUnwrap(try environment.headers(fromValueForKey: "HEADERS"))
        XCTAssertEqual(headers.count, 1)
        let (key, value) = try XCTUnwrap(headers.first)
        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, "value")
    }

    func test_headersFromValueForKey_stripsWhitespaceInValue() throws {
        let environment: OTelEnvironment = ["HEADERS": "key=  value "]

        let headers = try XCTUnwrap(try environment.headers(fromValueForKey: "HEADERS"))
        XCTAssertEqual(headers.count, 1)
        let (key, value) = try XCTUnwrap(headers.first)
        XCTAssertEqual(key, "key")
        XCTAssertEqual(value, "value")
    }

    func test_headersFromValueForKey_multipleHeaders_withWhitespace() throws {
        let environment: OTelEnvironment = ["HEADERS": " key1=foo  , key2  = bar     "]

        let headers = try XCTUnwrap(try environment.headers(fromValueForKey: "HEADERS"))
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers[0].key, "key1")
        XCTAssertEqual(headers[0].value, "foo")
        XCTAssertEqual(headers[1].key, "key2")
        XCTAssertEqual(headers[1].value, "bar")
    }

    func test_headersFromValueForKey_multipleHeaders_withoutValue() throws {
        let environment: OTelEnvironment = ["HEADERS": " key1=,key2=value"]

        let headers = try XCTUnwrap(try environment.headers(fromValueForKey: "HEADERS"))
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers[0].key, "key1")
        XCTAssertEqual(headers[0].value, "")
        XCTAssertEqual(headers[1].key, "key2")
        XCTAssertEqual(headers[1].value, "value")
    }

    func test_headersFromValueForKey_withoutValueSeparator_throwsEnvironmentValueError() throws {
        let environment: OTelEnvironment = ["HEADERS": "this-is-still-the-key"]

        do {
            let headers = try environment.headers(fromValueForKey: "HEADERS")
            XCTFail("Expected to fail parsing headers, got \(headers ?? [])")
        } catch let error as OTelEnvironmentValueError {
            XCTAssertEqual(error, OTelEnvironmentValueError(key: "HEADERS", value: "this-is-still-the-key"))
        }
    }

    // MARK: - value

    func test_value_withProgrammaticOverride_returnsProgrammaticOverride() throws {
        let environment = OTelEnvironment(values: [
            "specific": "1",
            "shared": "2",
        ])

        let value = try environment.value(
            programmaticOverride: 42,
            signalSpecificKey: "specific",
            sharedKey: "shared",
            transformValue: { _ in nil }
        )

        XCTAssertEqual(value, 42)
    }

    func test_value_withValidSpecificEnvironmentValue_returnsSpecificEnvironmentValue() throws {
        let environment = OTelEnvironment(values: [
            "specific": "1.1",
            "shared": "2.2",
        ])

        let value = try environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "specific",
            sharedKey: "shared",
            transformValue: Double.init
        )

        XCTAssertEqual(value, 1.1)
    }

    func test_value_withValidSharedEnvironmentValue_returnsSharedEnvironmentValue() throws {
        let environment = OTelEnvironment(values: ["shared": "2"])

        let value = try environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "specific",
            sharedKey: "shared",
            transformValue: Int.init
        )

        XCTAssertEqual(value, 2)
    }

    func test_value_withoutEnvironmentValues_returnsNil() throws {
        let environment = OTelEnvironment(values: [:])

        let value = try environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "specific",
            sharedKey: "shared",
            transformValue: Int.init
        )

        XCTAssertNil(value)
    }

    func test_value_withMalformedEnvironmentValue_throwsEnvironmentValueError() throws {
        let environment = OTelEnvironment(values: ["specific": "not-an-int"])

        do {
            let value = try environment.value(
                programmaticOverride: nil,
                signalSpecificKey: "specific",
                sharedKey: "shared",
                transformValue: Int.init
            )
            if let value {
                XCTFail("Expected transforming value to fail, got value: \(value).")
            } else {
                XCTFail("Expected transforming value to fail, got nil.")
            }
        } catch let error as OTelEnvironmentValueError {
            XCTAssertEqual(error, OTelEnvironmentValueError(key: "specific", value: "not-an-int"))
        }
    }

    func test_value_bool_withLowercasedTrue_returnsTrue() throws {
        let environment = OTelEnvironment(values: ["a": "true"])

        XCTAssertTrue(try XCTUnwrap(environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "a",
            sharedKey: "b"
        )))
    }

    func test_value_bool_withUppercasedTrue_returnsTrue() throws {
        let environment = OTelEnvironment(values: ["a": "TRUE"])

        XCTAssertTrue(try XCTUnwrap(environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "a",
            sharedKey: "b"
        )))
    }

    func test_value_bool_withWeirdCasedTrue_returnsTrue() throws {
        let environment = OTelEnvironment(values: ["a": "TrUe"])

        XCTAssertTrue(try XCTUnwrap(environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "a",
            sharedKey: "b"
        )))
    }

    func test_value_bool_withLowercasedFalse_returnsFalse() throws {
        let environment = OTelEnvironment(values: ["a": "false"])

        XCTAssertFalse(try XCTUnwrap(environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "a",
            sharedKey: "b"
        )))
    }

    func test_value_bool_withUppercasedFalse_returnsFalse() throws {
        let environment = OTelEnvironment(values: ["a": "FALSE"])

        XCTAssertFalse(try XCTUnwrap(environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "a",
            sharedKey: "b"
        )))
    }

    func test_value_bool_withWeirdCasedFalse_returnsFalse() throws {
        let environment = OTelEnvironment(values: ["a": "FaLSe"])

        XCTAssertFalse(try XCTUnwrap(environment.value(
            programmaticOverride: nil,
            signalSpecificKey: "a",
            sharedKey: "b"
        )))
    }

    func test_value_bool_withMalformedEnvironmentValue_throwsEnvironmentValueError() throws {
        let environment = OTelEnvironment(values: ["a": "not-a-bool"])

        do {
            let value = try environment.value(
                programmaticOverride: nil,
                signalSpecificKey: "a",
                sharedKey: "b"
            )
            if let value {
                XCTFail("Expected transforming value to fail, got value: \(value).")
            } else {
                XCTFail("Expected transforming value to fail, got nil.")
            }
        } catch let error as OTelEnvironmentValueError {
            XCTAssertEqual(error, OTelEnvironmentValueError(key: "a", value: "not-a-bool"))
        }
    }
}
