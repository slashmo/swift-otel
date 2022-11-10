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

@testable import Logging
import NIO
@testable import OpenTelemetry
import XCTest

final class OTelTests: XCTestCase {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    override func setUpWithError() throws {
        LoggingSystem.bootstrapInternal {
            var handler = StreamLogHandler.standardOutput(label: $0)
            handler.logLevel = .debug
            return handler
        }
    }

    func test_detectsResourceAttributes() {
        let otel = OTel(
            resource: OTel.Resource(attributes: ["service.name": #function]),
            eventLoopGroup: eventLoopGroup
        )
        XCTAssertNoThrow(try otel.start().wait())

        let attributes = otel.resource.attributes
        XCTAssertNotNil(attributes["telemetry.sdk.name"])
        XCTAssertNotNil(attributes["telemetry.sdk.language"])
        XCTAssertNotNil(attributes["telemetry.sdk.version"])

        XCTAssertGreaterThan(attributes.count, 3, "Expected more than 3 detected resource attributes.")

        XCTAssertNoThrow(try otel.shutdown().wait())
    }
}
