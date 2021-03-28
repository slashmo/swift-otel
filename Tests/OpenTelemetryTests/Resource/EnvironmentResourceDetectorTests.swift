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

import NIO
@testable import OpenTelemetry
import XCTest

final class EnvironmentResourceDetectorTests: XCTestCase {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    func test_detectsEmptyResource_FromMissingEnvironmentVariable() throws {
        let detector = OTel.EnvironmentResourceDetector(eventLoopGroup: eventLoopGroup, environment: [:])

        let resource = try detector.detect().wait()

        XCTAssertTrue(resource.attributes.isEmpty)
    }

    func test_detectsEnvironmentVariable() throws {
        let environment = [
            "PORT": "8080",
            "OTEL_RESOURCE_ATTRIBUTES": "key=value,nested.key=1",
        ]
        let detector = OTel.EnvironmentResourceDetector(eventLoopGroup: eventLoopGroup, environment: environment)

        let resource = try detector.detect().wait()

        XCTAssertEqual(resource.attributes["key"]?.toSpanAttribute(), "value")

        // "All attribute values MUST be considered strings"
        // https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/resource/sdk.md#specifying-resource-information-via-an-environment-variable
        XCTAssertEqual(resource.attributes["nested.key"]?.toSpanAttribute(), "1")
    }

    func test_rejectsInvalidKeyValuePair() throws {
        let environment = [
            "PORT": "8080",
            "OTEL_RESOURCE_ATTRIBUTES": "key=value,missing.value",
        ]
        let detector = OTel.EnvironmentResourceDetector(eventLoopGroup: eventLoopGroup, environment: environment)

        XCTAssertThrowsError(try detector.detect().wait()) { error in
            guard case OTel.EnvironmentResourceDetector.Error.invalidKeyValuePair("missing.value") = error else {
                XCTFail("Expected invalidKeyValuePair error, but got: \(error)")
                return
            }
        }
    }
}
