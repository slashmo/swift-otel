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

final class NoOpSpanExporterTests: XCTestCase {
    func test_alwaysSucceeds() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let exporter = OTel.NoOpSpanExporter(eventLoopGroup: eventLoopGroup)

        let span = OTel.Tracer.Span.stub()
        span.end()
        let recordedSpan = try XCTUnwrap(OTel.RecordedSpan(span))

        XCTAssertNoThrow(exporter.exportSpans([recordedSpan]))
    }
}
