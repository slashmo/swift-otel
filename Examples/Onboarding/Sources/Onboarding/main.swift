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

import Logging
import NIO
import OpenTelemetry
import OtlpGRPCSpanExporting
import Tracing

// In a real application, you should re-use your existing
// event loop group instead of creating a new one.
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = .trace
    return handler
}

// MARK: - Configure OTel

let exporter = OtlpGRPCSpanExporter(config: OtlpGRPCSpanExporter.Config(eventLoopGroup: group))
let processor = OTel.SimpleSpanProcessor(exportingTo: exporter)
let otel = OTel(serviceName: "onboarding", eventLoopGroup: group, processor: processor)

// First start `OTel`, then bootstrap the instrumentation system.
// This makes sure that all components are ready to begin handling spans.
try otel.start().wait()

// By bootstrapping the instrumentation system, our dependencies
// compatible with "Swift Distributed Tracing" will also automatically
// use the "OpenTelemetry Swift" Tracer 🚀.
InstrumentationSystem.bootstrap(otel.tracer())

// MARK: - Create spans

let rootSpan = InstrumentationSystem.tracer.startSpan("hello", baggage: .topLevel)
sleep(1)
rootSpan.addEvent(SpanEvent(name: "Discovered the meaning of life", attributes: ["meaning_of_life": 42]))

// By passing `rootSpan`'s baggage, "OpenTelemetry Swift" will automatically create it as child span.
let childSpan = InstrumentationSystem.tracer.startSpan("world", baggage: rootSpan.baggage)
sleep(1)
childSpan.end()
sleep(1)
rootSpan.end()

// MARK: - Shutdown

// Wait a second to let the exporter finish before shutting down.
sleep(1)

try otel.shutdown().wait()
try group.syncShutdownGracefully()
