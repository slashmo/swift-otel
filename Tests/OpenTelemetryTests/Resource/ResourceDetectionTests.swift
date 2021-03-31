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
import Tracing
import XCTest

final class ResourceDetectionTests: XCTestCase {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    func test_automatic() throws {
        let resourceDetection = OTel.ResourceDetection.automatic(additionalDetectors: [
            CustomResourceDetector(eventLoopGroup: eventLoopGroup),
        ])
        let resource = try resourceDetection.detectAttributes(
            for: OTel.Resource(),
            on: eventLoopGroup
        ).wait()

        XCTAssertNotNil(resource.attributes["process.executable.name"])
        XCTAssertNotNil(resource.attributes["process.executable.path"])
        XCTAssertNotNil(resource.attributes["process.command"])
        XCTAssertNotNil(resource.attributes["process.command_line"])
        XCTAssertEqual(resource.attributes["process.pid"]?.toSpanAttribute(), 42)
        XCTAssertEqual(resource.attributes["custom"]?.toSpanAttribute(), "value")
    }

    func test_manual() throws {
        let resourceDetection = OTel.ResourceDetection.manual(OTel.Resource(attributes: ["key": "value"]))

        let resource = try resourceDetection.detectAttributes(
            for: OTel.Resource(),
            on: eventLoopGroup
        ).wait()

        XCTAssertEqual(resource.attributes.count, 4)
        XCTAssertEqual(resource.attributes["key"]?.toSpanAttribute(), "value")
        XCTAssertNotNil(resource.attributes["telemetry.sdk.name"])
        XCTAssertNotNil(resource.attributes["telemetry.sdk.language"])
        XCTAssertNotNil(resource.attributes["telemetry.sdk.version"])
    }

    func test_none() throws {
        let resourceDetection = OTel.ResourceDetection.none

        let resource = try resourceDetection.detectAttributes(
            for: OTel.Resource(),
            on: eventLoopGroup
        ).wait()

        XCTAssertTrue(resource.attributes.isEmpty)
    }
}

private struct CustomResourceDetector: OTelResourceDetector {
    private let eventLoopGroup: EventLoopGroup

    init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }

    func detect() -> EventLoopFuture<OTel.Resource> {
        eventLoopGroup.next().makeSucceededFuture(
            OTel.Resource(attributes: ["custom": "value", "process.pid": .int(42)])
        )
    }
}
