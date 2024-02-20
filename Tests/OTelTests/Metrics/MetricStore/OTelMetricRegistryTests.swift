//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import struct NIOConcurrencyHelpers.NIOLockedValueBox
@testable import OTel
import OTelTesting
import XCTest

final class OTelMetricRegistryTests: XCTestCase {
    func test_identity_SameName_Identical() {
        let registry = OTelMetricRegistry()
        XCTAssertIdentical(
            registry.makeCounter(name: "c"),
            registry.makeCounter(name: "c")
        )
        XCTAssertIdentical(
            registry.makeGauge(name: "g"),
            registry.makeGauge(name: "g")
        )
        XCTAssertIdentical(
            registry.makeDurationHistogram(name: "d", buckets: []),
            registry.makeDurationHistogram(name: "d", buckets: [])
        )
        XCTAssertIdentical(
            registry.makeValueHistogram(name: "v", buckets: []),
            registry.makeValueHistogram(name: "v", buckets: [])
        )
    }

    func test_identity_sameNameDifferentCase_identical() throws {
        let registry = OTelMetricRegistry()

        XCTAssertIdentical(
            registry.makeCounter(name: "c"),
            registry.makeCounter(name: "C")
        )
        XCTAssertIdentical(
            registry.makeGauge(name: "G"),
            registry.makeGauge(name: "g")
        )
        XCTAssertIdentical(
            registry.makeDurationHistogram(name: "duration_histogram", buckets: []),
            registry.makeDurationHistogram(name: "dUrAtIoN_hIsToGrAm", buckets: [])
        )
        XCTAssertIdentical(
            registry.makeValueHistogram(name: "value_histogram", buckets: []),
            registry.makeValueHistogram(name: "vAlUe_hIsToGrAm", buckets: [])
        )
    }

    func test_identity_sameNameSameLabels_identical() {
        let registry = OTelMetricRegistry()
        XCTAssertIdentical(
            registry.makeCounter(name: "c", labels: [("one", "1")]),
            registry.makeCounter(name: "c", labels: [("one", "1")])
        )
        XCTAssertIdentical(
            registry.makeGauge(name: "g", labels: [("one", "1")]),
            registry.makeGauge(name: "g", labels: [("one", "1")])
        )
        XCTAssertIdentical(
            registry.makeDurationHistogram(name: "d", labels: [("one", "1")], buckets: []),
            registry.makeDurationHistogram(name: "d", labels: [("one", "1")], buckets: [])
        )
        XCTAssertIdentical(
            registry.makeValueHistogram(name: "v", labels: [("one", "1")], buckets: []),
            registry.makeValueHistogram(name: "v", labels: [("one", "1")], buckets: [])
        )
    }

    func test_identity_sameNameDifferentOrder_identical() {
        let registry = OTelMetricRegistry()
        XCTAssertIdentical(
            registry.makeCounter(name: "c", labels: [("one", "1"), ("two", "2")]),
            registry.makeCounter(name: "c", labels: [("two", "2"), ("one", "1")])
        )
        XCTAssertIdentical(
            registry.makeGauge(name: "g", labels: [("one", "1"), ("two", "2")]),
            registry.makeGauge(name: "g", labels: [("two", "2"), ("one", "1")])
        )
        XCTAssertIdentical(
            registry.makeDurationHistogram(name: "d", labels: [("one", "1"), ("two", "2")], buckets: []),
            registry.makeDurationHistogram(name: "d", labels: [("two", "2"), ("one", "1")], buckets: [])
        )
        XCTAssertIdentical(
            registry.makeValueHistogram(name: "v", labels: [("one", "1"), ("two", "2")], buckets: []),
            registry.makeValueHistogram(name: "v", labels: [("two", "2"), ("one", "1")], buckets: [])
        )
    }

    func test_identity_differentNamesNoLabels_distinct() {
        let registry = OTelMetricRegistry()
        XCTAssertNotIdentical(
            registry.makeCounter(name: "c1"),
            registry.makeCounter(name: "c2")
        )
        XCTAssertNotIdentical(
            registry.makeGauge(name: "g1"),
            registry.makeGauge(name: "g2")
        )
        XCTAssertNotIdentical(
            registry.makeDurationHistogram(name: "h1", buckets: []),
            registry.makeDurationHistogram(name: "h2", buckets: [])
        )
        XCTAssertNotIdentical(
            registry.makeValueHistogram(name: "v1", buckets: []),
            registry.makeValueHistogram(name: "v2", buckets: [])
        )
    }

    func test_identity_sameNameSameLabelKeysDifferentValues_distinct() {
        let registry = OTelMetricRegistry()
        XCTAssertNotIdentical(
            registry.makeCounter(name: "c", labels: [("x", "1"), ("y", "2")]),
            registry.makeCounter(name: "c", labels: [("x", "2"), ("y", "4")])
        )
        XCTAssertNotIdentical(
            registry.makeGauge(name: "g", labels: [("x", "1"), ("y", "2")]),
            registry.makeGauge(name: "g", labels: [("x", "2"), ("y", "4")])
        )
        XCTAssertNotIdentical(
            registry.makeDurationHistogram(name: "d", labels: [("x", "1"), ("y", "2")], buckets: []),
            registry.makeDurationHistogram(name: "d", labels: [("x", "2"), ("y", "4")], buckets: [])
        )
        XCTAssertNotIdentical(
            registry.makeValueHistogram(name: "v", labels: [("x", "1"), ("y", "2")], buckets: []),
            registry.makeValueHistogram(name: "v", labels: [("x", "2"), ("y", "4")], buckets: [])
        )
    }

    func test_identity_sameNameDifferentLabelKeys_distinct() throws {
        let registry = OTelMetricRegistry()

        XCTAssertNotIdentical(
            registry.makeCounter(name: "c", labels: [("x", "1")]),
            registry.makeCounter(name: "c", labels: [("y", "1")])
        )
        XCTAssertNotIdentical(
            registry.makeGauge(name: "g", labels: [("x", "1")]),
            registry.makeGauge(name: "g", labels: [("y", "1")])
        )
        XCTAssertNotIdentical(
            registry.makeDurationHistogram(name: "d", labels: [("x", "1")], buckets: []),
            registry.makeDurationHistogram(name: "d", labels: [("y", "1")], buckets: [])
        )
        XCTAssertNotIdentical(
            registry.makeValueHistogram(name: "v", labels: [("x", "1")], buckets: []),
            registry.makeValueHistogram(name: "v", labels: [("y", "1")], buckets: [])
        )
    }

    func test_identity_sameNameAdditionalLabels_distinct() throws {
        let registry = OTelMetricRegistry()

        XCTAssertNotIdentical(
            registry.makeCounter(name: "c", labels: [("x", "1")]),
            registry.makeCounter(name: "c", labels: [("x", "1"), ("y", "1")])
        )

        XCTAssertNotIdentical(
            registry.makeGauge(name: "g", labels: [("x", "1")]),
            registry.makeGauge(name: "g", labels: [("x", "1"), ("y", "1")])
        )

        XCTAssertNotIdentical(
            registry.makeDurationHistogram(name: "d", labels: [("x", "1")], buckets: []),
            registry.makeDurationHistogram(name: "d", labels: [("x", "1"), ("y", "1")], buckets: [])
        )
        XCTAssertNotIdentical(
            registry.makeValueHistogram(name: "v", labels: [("x", "1")], buckets: []),
            registry.makeValueHistogram(name: "v", labels: [("x", "1"), ("y", "1")], buckets: [])
        )
    }

    func test_identity_sameNameSameLabelsDifferentBuckets_identical() throws {
        let registry = OTelMetricRegistry()

        XCTAssertIdentical(
            registry.makeDurationHistogram(name: "d", labels: [("x", "1")], buckets: [.seconds(1)]),
            registry.makeDurationHistogram(name: "d", labels: [("x", "1")], buckets: [.seconds(2)])
        )
        XCTAssertIdentical(
            registry.makeValueHistogram(name: "v", labels: [("x", "1")], buckets: [1]),
            registry.makeValueHistogram(name: "v", labels: [("x", "1")], buckets: [2])
        )
    }

    func test_identity_sameNameDifferentIdentity_distinctAndCallsHandler() throws {
        let handler = RecordingDuplicateRegistrationHandler()
        let registry = OTelMetricRegistry(duplicateRegistrationHandler: handler)

        // Start with no invocations.
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 0)

        // Registering a new metric does not invoke handler.
        _ = registry.makeCounter(name: "name", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 0)

        // Registering the same metric does not invoke handler.
        _ = registry.makeCounter(name: "name", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 0)

        // Registering a metric with the same identifying fields but different attributes does not invoke handler.
        _ = registry.makeCounter(name: "name", labels: [("y", "2")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 0)

        // Registring a metric of the same type but with a different identifying field invokes the handler once only.
        _ = registry.makeCounter(name: "name", unit: "new_unit", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 1)
        _ = registry.makeCounter(name: "name", unit: "new_unit", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 1)

        // OTel spec also states that description is also an identifying field.
        _ = registry.makeCounter(name: "name", unit: "new_unit", description: "new description", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 2)
        _ = registry.makeCounter(name: "name", unit: "new_unit", description: "new description", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 2)

        // The kind of instrument is, of course, also an identifying field.
        _ = registry.makeGauge(name: "name", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 3)
        _ = registry.makeGauge(name: "name", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 3)

        // Same for histogram...
        _ = registry.makeValueHistogram(name: "name", labels: [("x", "1")], buckets: [1])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 4)
        _ = registry.makeValueHistogram(name: "name", labels: [("x", "1")], buckets: [1])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 4)

        // ...but currently we do _not_ consider the buckets to be identifying.
        _ = registry.makeValueHistogram(name: "name", labels: [("x", "1")], buckets: [2])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 4)

        // While name is an identifying field, it is treated case-insensitively.
        _ = registry.makeCounter(name: "NaMe", labels: [("x", "1")])
        XCTAssertEqual(handler.invocations.withLockedValue { $0.count }, 4)
    }

    func test_unregisterReregister_withoutLabels() {
        let duplicateRegistrationHandler = RecordingDuplicateRegistrationHandler()
        let registry = OTelMetricRegistry(duplicateRegistrationHandler: duplicateRegistrationHandler)

        registry.unregisterCounter(registry.makeCounter(name: "name"))
        registry.unregisterGauge(registry.makeGauge(name: "name"))
        registry.unregisterDurationHistogram(registry.makeDurationHistogram(name: "name", buckets: []))
        registry.unregisterValueHistogram(registry.makeValueHistogram(name: "name", buckets: []))
        _ = registry.makeCounter(name: "name")

        XCTAssertEqual(duplicateRegistrationHandler.invocations.withLockedValue { $0 }.count, 0)
    }

    func test_unregisterReregister_withLabels() {
        let duplicateRegistrationHandler = RecordingDuplicateRegistrationHandler()
        let registry = OTelMetricRegistry(duplicateRegistrationHandler: duplicateRegistrationHandler)

        registry.unregisterCounter(registry.makeCounter(name: "name", labels: [("a", "1")]))
        registry.unregisterCounter(registry.makeCounter(name: "name", labels: [("b", "1")]))

        registry.unregisterGauge(registry.makeGauge(name: "name", labels: [("a", "1")]))
        registry.unregisterGauge(registry.makeGauge(name: "name", labels: [("b", "1")]))

        registry.unregisterDurationHistogram(registry.makeDurationHistogram(name: "name", labels: [("a", "1")], buckets: []))
        registry.unregisterDurationHistogram(registry.makeDurationHistogram(name: "name", labels: [("b", "1")], buckets: []))

        registry.unregisterValueHistogram(registry.makeValueHistogram(name: "name", labels: [("a", "1")], buckets: []))
        registry.unregisterValueHistogram(registry.makeValueHistogram(name: "name", labels: [("b", "1")], buckets: []))

        _ = registry.makeCounter(name: "name", labels: [("a", "1")])

        XCTAssertEqual(duplicateRegistrationHandler.invocations.withLockedValue { $0 }.count, 0)
    }
}

final class DuplicateRegistrationHandlerTests: XCTestCase {
    func test_LoggingDuplicateRegistrationHandler() {
        let recordingLogHandler = RecordingLogHandler()
        LoggingSystem.bootstrap { _ in recordingLogHandler }
        let handler = WarningDuplicateRegistrationHandler(logger: Logger(label: "test"))
        handler.handle(
            newRegistration: .counter(name: "name"),
            existingRegistrations: [.gauge(name: "name"), .histogram(name: "name")]
        )
        let recordedLogMessages = recordingLogHandler.recordedLogMessages.withLockedValue { $0 }
        XCTAssertEqual(recordedLogMessages.count, 1)
        XCTAssertEqual(recordedLogMessages.first?.level, .warning)
    }

    func test_FatalErrorDuplicateRegistrationHandler() {
        let handler = FatalErrorDuplicateRegistrationHandler()
        XCTAssertThrowsFatalError {
            handler.handle(
                newRegistration: .counter(name: "name"),
                existingRegistrations: [.gauge(name: "name"), .histogram(name: "name")]
            )
        }
    }

    func test_DuplicateRegistrationHandler_selection() {
        XCTAssert(OTelMetricRegistry(onDuplicateRegistration: .warn).storage.withLockedValue { $0 }.duplicateRegistrationHandler is WarningDuplicateRegistrationHandler)
        XCTAssert(OTelMetricRegistry(onDuplicateRegistration: .crash).storage.withLockedValue { $0 }.duplicateRegistrationHandler is FatalErrorDuplicateRegistrationHandler)
    }

    func test_DuplicateRegistrationHandler_default() {
        XCTAssert(OTelMetricRegistry().storage.withLockedValue { $0 }.duplicateRegistrationHandler is WarningDuplicateRegistrationHandler)
    }
}
