//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2020 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import GRPC
import Instrumentation
import NIO
import OpenTelemetry
import OtlpTraceExporting
import Tracing
import TracingOpenTelemetrySupport

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let channel = ClientConnection
    .insecure(group: eventLoopGroup)
    .connect(host: "localhost", port: 55680)
let exporter = OtlpTraceExporter(channel: channel)
let tracer = OpenTelemetryTracer(exporter: exporter)
InstrumentationSystem.bootstrap(tracer)

// MARK: - HTTP Client: Send Request
let clientSpan = InstrumentationSystem.tracer.startSpan("HTTP GET", baggage: .topLevel, ofKind: .client)
clientSpan.attributes.http.method = "GET"
clientSpan.attributes.http.flavor = "1.1"
clientSpan.attributes.http.url = "https://example.com:8080/webshop/articles/4?s=1"
clientSpan.attributes.net.peerIP = "192.0.2.5"

// MARK: - HTTP Server: Handle request
let serverSpan = InstrumentationSystem.tracer.startSpan("/webshop/articles/:article_id", baggage: clientSpan.baggage, ofKind: .server)
serverSpan.attributes.http.method = "GET"
serverSpan.attributes.http.flavor = "1.1"
serverSpan.attributes.http.target = "/webshop/articles/4?s=1"
serverSpan.attributes.http.serverRoute = "/webshop/articles/:article_id"
serverSpan.attributes.http.host = "example.com:8080"
serverSpan.attributes.http.serverName = "example.com"
serverSpan.attributes.http.scheme = "https"
serverSpan.attributes.net.hostPort = 8080
serverSpan.attributes.http.serverClientIP = "192.0.2.4"
serverSpan.attributes.net.peerIP = "192.0.2.5"
serverSpan.attributes.http.userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:72.0) Gecko/20100101 Firefox/72.0"

// MARK: - SQL Database: Execute Query
let dbSpan = InstrumentationSystem.tracer.startSpan("SQL SELECT", baggage: serverSpan.baggage, ofKind: .client)
dbSpan.attributes["sql.query"] = "SELECT * FROM articles WHERE article_id=?"
sleep(1)
dbSpan.addEvent("Retry query")
sleep(1)
dbSpan.setStatus(SpanStatus(canonicalCode: .ok))
dbSpan.end()

// MARK: - HTTP Server: Send Response
serverSpan.attributes.http.statusCode = 200
serverSpan.setStatus(SpanStatus(canonicalCode: .ok))
serverSpan.end()

// MARK: - HTTP Client: Handle Response
clientSpan.attributes.http.statusCode = 200
clientSpan.setStatus(SpanStatus(canonicalCode: .ok))
clientSpan.end()

try channel.close().wait()
