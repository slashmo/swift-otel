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

import Logging
@_spi(Testing) import OpenTelemetry
import OTelTesting
import Tracing
import XCTest

final class OTelResourceDetectionTests: XCTestCase {
    override func setUp() {
        LoggingSystem.bootstrapInternal(logLevel: .trace)
    }

    func test_resource_withAutomaticDetection_mergesDetectedResourcesInCorrectOrder() async {
        let logger = Logger(label: #function)

        struct AdditionalDetector: OTelResourceDetector {
            let description = "additional"

            func resource() async throws -> OTelResource {
                OTelResource(attributes: ["additional": "additional", "process.executable.name": "additional"])
            }
        }

        let detection = OTelResourceDetection.automatic(additionalDetectors: [AdditionalDetector()])
        let environment = OTelEnvironment(values: [
            "OTEL_RESOURCE_ATTRIBUTES": """
            environment=environment,additional=environment,process.pid=environment,process.executable.name=environment
            """,
        ])

        let processDetector = OTelProcessResourceDetector(
            processIdentifier: { 42 },
            executableName: { "test" },
            executablePath: { "test" },
            command: { nil },
            commandLine: { "test" },
            owner: { nil }
        )
        let environmentDetector = OTelEnvironmentResourceDetector(environment: environment)

        let resource = await detection.resource(
            processDetector: processDetector,
            environmentDetector: environmentDetector,
            logger: logger
        )

        XCTAssertEqual(resource, OTelResource(attributes: [
            "additional": "additional",
            "environment": "environment",
            "process.executable.name": "additional", // overriden by environment & additional detector
            "process.pid": "environment", // overriden by environment detector
            "process.executable.path": "test",
            "process.command_line": "test",
            "telemetry.sdk.name": "opentelemetry",
            "telemetry.sdk.language": "swift",
            "telemetry.sdk.version": "\(OTelLibrary.version)",
        ]))
    }

    func test_resource_withAutomaticDetection_filtersOutFailedDetectors() async {
        let logger = Logger(label: #function)

        struct FailingDetector: OTelResourceDetector {
            let description = "failing"

            func resource() async throws -> OTelResource {
                struct Error: Swift.Error {}
                throw Error()
            }
        }

        let detection = OTelResourceDetection.automatic(additionalDetectors: [FailingDetector()])
        let environment = OTelEnvironment(values: ["OTEL_RESOURCE_ATTRIBUTES": "environment=environment"])

        let processDetector = OTelProcessResourceDetector(
            processIdentifier: { 42 },
            executableName: { "test" },
            executablePath: { "test" },
            command: { nil },
            commandLine: { "test" },
            owner: { nil }
        )
        let environmentDetector = OTelEnvironmentResourceDetector(environment: environment)

        let resource = await detection.resource(
            processDetector: processDetector,
            environmentDetector: environmentDetector,
            logger: logger
        )

        XCTAssertEqual(resource, OTelResource(attributes: [
            "environment": "environment",
            "process.pid": .int32(42),
            "process.executable.name": "test",
            "process.executable.path": "test",
            "process.command_line": "test",
            "telemetry.sdk.name": "opentelemetry",
            "telemetry.sdk.language": "swift",
            "telemetry.sdk.version": "\(OTelLibrary.version)",
        ]))
    }

    func test_resource_withManualDetection_mergesSDKResourceWithManualResource() async {
        let logger = Logger(label: #function)

        let manualResource = OTelResource(attributes: ["manual": "manual", "telemetry.sdk.name": "manual"])
        let detection = OTelResourceDetection.manual(manualResource)

        let resource = await detection.resource(
            processDetector: OTelProcessResourceDetector(),
            environmentDetector: OTelEnvironmentResourceDetector(environment: [:]),
            logger: logger
        )

        XCTAssertEqual(resource, OTelResource(attributes: [
            "manual": "manual",
            "telemetry.sdk.name": "manual",
            "telemetry.sdk.language": "swift",
            "telemetry.sdk.version": "\(OTelLibrary.version)",
        ]))
    }

    func test_resource_withDisabledDetection_returnsEmptyResource() async {
        let logger = Logger(label: #function)
        let detection = OTelResourceDetection.disabled

        let resource = await detection.resource(
            processDetector: OTelProcessResourceDetector(),
            environmentDetector: OTelEnvironmentResourceDetector(environment: [:]),
            logger: logger
        )

        XCTAssertTrue(resource.attributes.isEmpty)
    }
}
