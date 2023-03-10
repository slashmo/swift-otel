//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIO
import OpenTelemetry
import OtlpGRPCSpanExporting
import Tracing

@main
enum Onboarding {
    static func main() async throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let logExporter = OtlpGRPCLogRecordExporter(config: .init(eventLoopGroup: group))
        let logProcessor = OTel.SimpleLogRecordProcessor(exportingTo: logExporter)

        LoggingSystem.bootstrap({ label, _ in
            var handler = MultiplexLogHandler([
                OTelLogHandler(label: label, processor: logProcessor),
                StreamLogHandler.standardOutput(label: label),
            ])
            handler.logLevel = .debug
            return handler
        }, metadataProvider: .otel)

        let logger = Logger(label: "onboarding")

        let spanExporter = OtlpGRPCSpanExporter(config: .init(eventLoopGroup: group))
        let spanProcessor = OTel.SimpleSpanProcessor(exportingTo: spanExporter)

        let otel = OTel(serviceName: "onboarding", eventLoopGroup: group, processor: spanProcessor)

        try await otel.start().get()
        InstrumentationSystem.bootstrap(otel.tracer())

        try await InstrumentationSystem.tracer.withSpan("root") { _ in
            logger.info("start root", metadata: ["foo": "bar"])
            try await Task.sleep(for: .milliseconds(500))

            logger.info("kick off child", metadata: ["foo": "bar"])

            try await InstrumentationSystem.tracer.withSpan("child") { _ in
                logger.info("start child")
                try await Task.sleep(for: .seconds(1))
                logger.info("complete child")
            }

            try await Task.sleep(for: .milliseconds(500))

            logger.info("complete root")
        }

        try await Task.sleep(for: .seconds(20))
        try await group.shutdownGracefully()
    }
}
