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

final class OTelBatchSpanProcessorConfigurationTests: XCTestCase {
    // MARK: - maximumQueueSize

    func test_maximumQueueSize_withProgrammaticOverride_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            maximumQueueSize: 42
        )

        XCTAssertEqual(configuration.maximumQueueSize, 42)
    }

    func test_maximumQueueSize_withEnvironmentValue_usesEnvironmentValue() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_MAX_QUEUE_SIZE": "42"])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            maximumQueueSize: nil
        )

        XCTAssertEqual(configuration.maximumQueueSize, 42)
    }

    func test_maximumQueueSize_withProgrammaticOverrideAndEnvironmentValue_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_MAX_QUEUE_SIZE": "42"])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            maximumQueueSize: 84
        )

        XCTAssertEqual(configuration.maximumQueueSize, 84)
    }

    func test_maximumQueueSize_withoutConfiguration_usesDefaultValue() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessor.Configuration(environment: environment)

        XCTAssertEqual(configuration.maximumQueueSize, 2048)
    }

    // MARK: - scheduleDelayInMilliseconds

    func test_scheduleDelayInMilliseconds_withProgrammaticOverride_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            scheduleDelayInMilliseconds: 42
        )

        XCTAssertEqual(configuration.scheduleDelayInMilliseconds, 42)
    }

    func test_scheduleDelayInMilliseconds_withEnvironmentValue_usesEnvironmentValue() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_SCHEDULE_DELAY": "42"])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            scheduleDelayInMilliseconds: nil
        )

        XCTAssertEqual(configuration.scheduleDelayInMilliseconds, 42)
    }

    func test_scheduleDelayInMilliseconds_withProgrammaticOverrideAndEnvironmentValue_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_SCHEDULE_DELAY": "42"])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            scheduleDelayInMilliseconds: 84
        )

        XCTAssertEqual(configuration.scheduleDelayInMilliseconds, 84)
    }

    func test_scheduleDelayInMilliseconds_withoutConfiguration_usesDefaultValue() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessor.Configuration(environment: environment)

        XCTAssertEqual(configuration.scheduleDelayInMilliseconds, 5000)
    }

    // MARK: - maximumExportBatchSize

    func test_maximumExportBatchSize_withProgrammaticOverride_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            maximumExportBatchSize: 42
        )

        XCTAssertEqual(configuration.maximumExportBatchSize, 42)
    }

    func test_maximumExportBatchSize_withEnvironmentValue_usesEnvironmentValue() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_MAX_EXPORT_BATCH_SIZE": "42"])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            maximumExportBatchSize: nil
        )

        XCTAssertEqual(configuration.maximumExportBatchSize, 42)
    }

    func test_maximumExportBatchSize_withProgrammaticOverrideAndEnvironmentValue_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_MAX_EXPORT_BATCH_SIZE": "42"])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            maximumExportBatchSize: 84
        )

        XCTAssertEqual(configuration.maximumExportBatchSize, 84)
    }

    func test_maximumExportBatchSize_withoutConfiguration_usesDefaultValue() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessor.Configuration(environment: environment)

        XCTAssertEqual(configuration.maximumExportBatchSize, 512)
    }

    // MARK: - exportTimeoutInMilliseconds

    func test_exportTimeoutInMilliseconds_withProgrammaticOverride_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            exportTimeoutInMilliseconds: 42
        )

        XCTAssertEqual(configuration.exportTimeoutInMilliseconds, 42)
    }

    func test_exportTimeoutInMilliseconds_withEnvironmentValue_usesEnvironmentValue() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_EXPORT_TIMEOUT": "42"])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            exportTimeoutInMilliseconds: nil
        )

        XCTAssertEqual(configuration.exportTimeoutInMilliseconds, 42)
    }

    func test_exportTimeoutInMilliseconds_withProgrammaticOverrideAndEnvironmentValue_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_EXPORT_TIMEOUT": "42"])

        let configuration = OTelBatchSpanProcessor.Configuration(
            environment: environment,
            exportTimeoutInMilliseconds: 84
        )

        XCTAssertEqual(configuration.exportTimeoutInMilliseconds, 84)
    }

    func test_exportTimeoutInMilliseconds_withoutConfiguration_usesDefaultValue() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessor.Configuration(environment: environment)

        XCTAssertEqual(configuration.exportTimeoutInMilliseconds, 30000)
    }
}
