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

import OTel
import XCTest

final class OTelBatchSpanProcessorConfigurationTests: XCTestCase {
    // MARK: - maximumQueueSize

    func test_maximumQueueSize_withProgrammaticOverride_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            maximumQueueSize: 42
        )

        XCTAssertEqual(configuration.maximumQueueSize, 42)
    }

    func test_maximumQueueSize_withEnvironmentValue_usesEnvironmentValue() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_MAX_QUEUE_SIZE": "42"])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            maximumQueueSize: nil
        )

        XCTAssertEqual(configuration.maximumQueueSize, 42)
    }

    func test_maximumQueueSize_withProgrammaticOverrideAndEnvironmentValue_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_MAX_QUEUE_SIZE": "42"])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            maximumQueueSize: 84
        )

        XCTAssertEqual(configuration.maximumQueueSize, 84)
    }

    func test_maximumQueueSize_withoutConfiguration_usesDefaultValue() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessorConfiguration(environment: environment)

        XCTAssertEqual(configuration.maximumQueueSize, 2048)
    }

    // MARK: - scheduleDelay

    func test_scheduleDelay_withProgrammaticOverride_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            scheduleDelay: .milliseconds(42)
        )

        XCTAssertEqual(configuration.scheduleDelay, .milliseconds(42))
    }

    func test_scheduleDelay_withEnvironmentValue_usesEnvironmentValue() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_SCHEDULE_DELAY": "42"])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            scheduleDelay: nil
        )

        XCTAssertEqual(configuration.scheduleDelay, .milliseconds(42))
    }

    func test_scheduleDelay_withProgrammaticOverrideAndEnvironmentValue_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_SCHEDULE_DELAY": "42"])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            scheduleDelay: .milliseconds(84)
        )

        XCTAssertEqual(configuration.scheduleDelay, .milliseconds(84))
    }

    func test_scheduleDelay_withoutConfiguration_usesDefaultValue() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessorConfiguration(environment: environment)

        XCTAssertEqual(configuration.scheduleDelay, .seconds(5))
    }

    // MARK: - maximumExportBatchSize

    func test_maximumExportBatchSize_withProgrammaticOverride_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            maximumExportBatchSize: 42
        )

        XCTAssertEqual(configuration.maximumExportBatchSize, 42)
    }

    func test_maximumExportBatchSize_withEnvironmentValue_usesEnvironmentValue() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_MAX_EXPORT_BATCH_SIZE": "42"])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            maximumExportBatchSize: nil
        )

        XCTAssertEqual(configuration.maximumExportBatchSize, 42)
    }

    func test_maximumExportBatchSize_withProgrammaticOverrideAndEnvironmentValue_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_MAX_EXPORT_BATCH_SIZE": "42"])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            maximumExportBatchSize: 84
        )

        XCTAssertEqual(configuration.maximumExportBatchSize, 84)
    }

    func test_maximumExportBatchSize_withoutConfiguration_usesDefaultValue() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessorConfiguration(environment: environment)

        XCTAssertEqual(configuration.maximumExportBatchSize, 512)
    }

    // MARK: - exportTimeout

    func test_exportTimeout_withProgrammaticOverride_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            exportTimeout: .milliseconds(42)
        )

        XCTAssertEqual(configuration.exportTimeout, .milliseconds(42))
    }

    func test_exportTimeout_withEnvironmentValue_usesEnvironmentValue() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_EXPORT_TIMEOUT": "42"])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            exportTimeout: nil
        )

        XCTAssertEqual(configuration.exportTimeout, .milliseconds(42))
    }

    func test_exportTimeout_withProgrammaticOverrideAndEnvironmentValue_usesProgrammaticOverride() {
        let environment = OTelEnvironment(values: ["OTEL_BSP_EXPORT_TIMEOUT": "42"])

        let configuration = OTelBatchSpanProcessorConfiguration(
            environment: environment,
            exportTimeout: .milliseconds(84)
        )

        XCTAssertEqual(configuration.exportTimeout, .milliseconds(84))
    }

    func test_exportTimeout_withoutConfiguration_usesDefaultValue() {
        let environment = OTelEnvironment(values: [:])

        let configuration = OTelBatchSpanProcessorConfiguration(environment: environment)

        XCTAssertEqual(configuration.exportTimeout, .seconds(30))
    }
}
