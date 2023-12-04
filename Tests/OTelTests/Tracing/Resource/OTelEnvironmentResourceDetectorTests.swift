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

@_spi(Testing) import OTel
import Tracing
import XCTest

final class OTelEnvironmentResourceDetectorTests: XCTestCase {
    func test_resource_withValidEnvironmentVariable_returnsResource() async throws {
        let environment = OTelEnvironment(values: [
            "OTEL_RESOURCE_ATTRIBUTES": "service.name=test,service.version=1.2.3",
        ])
        let detector = OTelEnvironmentResourceDetector(environment: environment)

        let resource = try await detector.resource()

        XCTAssertEqual(resource, OTelResource(attributes: ["service.name": "test", "service.version": "1.2.3"]))
    }

    func test_resource_withoutEnvironmentVariable_returnsEmptyResource() async throws {
        let environment = OTelEnvironment()
        let detector = OTelEnvironmentResourceDetector(environment: environment)

        let resource = try await detector.resource()

        XCTAssertEqual(resource, OTelResource())
    }

    func test_resource_withEmptyEnvironmentValue_returnsEmptyResource() async throws {
        let environment = OTelEnvironment(values: ["OTEL_RESOURCE_ATTRIBUTES": ""])
        let detector = OTelEnvironmentResourceDetector(environment: environment)

        let resource = try await detector.resource()

        XCTAssertEqual(resource, OTelResource())
    }

    func test_resource_withMalformedEnvironmentValue_throwsError() async throws {
        let environment = OTelEnvironment(
            values: ["OTEL_RESOURCE_ATTRIBUTES": "service.name=test,service.version,service.id=42"]
        )
        let detector = OTelEnvironmentResourceDetector(environment: environment)

        do {
            let resource = try await detector.resource()
            XCTFail("Expected error, got resource: \(resource)")
        } catch let error as OTelEnvironmentResourceDetector.Error {
            XCTAssertEqual(error, .invalidKeyValuePair(["service.version"]))
        }
    }
}
