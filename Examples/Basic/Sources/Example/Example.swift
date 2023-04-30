//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2020-2023 Moritz Lang and the Swift OpenTelemetry project authors
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
import TracingOpenTelemetrySemanticConventions

@main
enum Example {
    static func example() async throws {
        let logger = Logger(label: "example")

        /*
         In this example, we simulate an HTTP server handling a product info request.
         The server "queries" the database, but the first attempt fails so it retries.
         */

        try await withSpan("/products/:product_id", ofKind: .client) { serverSpan in
            serverSpan.attributes.http.method = "GET"
            serverSpan.attributes.http.flavor = "1.1"
            serverSpan.attributes.http.target = "/products/42"

            logger.debug("Query product.", metadata: ["product_id": "42"])

            do {
                // our first attempt to fetch the product fails ...
                try await product(byID: 42, failRequest: true)
            } catch {
                // ... so we re-try the request
                serverSpan.addEvent("Retry product request.")
                try await product(byID: 42, failRequest: false)
            }

            serverSpan.attributes.http.statusCode = 200
        }
    }

    static func main() async throws {
        // MARK: - Set up

        // In a real application you'll most probably want to re-use your
        // existing event loop group instead of creating a new one.
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let otel = try setUp(in: eventLoopGroup)

        try await example()

        // MARK: - Shutdown

        // Wait for the exporter to finish before shutting down.
        sleep(10)

        try await otel.shutdown().get()
        try await eventLoopGroup.shutdownGracefully()
    }

    private static func product(byID: Int, failRequest: Bool) async throws {
        let logger = Logger(label: "database")

        struct DatabaseError: Error, CustomStringConvertible {
            let description = "Something went wrong, but the request should be retried."
        }

        try await withSpan("SELECT ShopDB.products", ofKind: .client) { dbSpan in
            dbSpan.attributes.db.system = "postgresql"
            dbSpan.attributes.db.statement = "SELECT * FROM products WHERE id = '42';"

            try await Task.sleep(for: .milliseconds(.random(in: 500 ..< 5000)))

            logger.debug("Finished DB query.")

            if failRequest {
                logger.error("Failed to fetch product info.")
                dbSpan.setStatus(.init(code: .error))
                throw DatabaseError()
            }
        }
    }

    private static func setUp(in eventLoopGroup: any EventLoopGroup) throws -> OTel {
        // MARK: - Bootstrap Logging

        LoggingSystem.bootstrap { label in
            /*
             Here we're using the default StreamLogHandler from swift-log and
             configure it to use the swift-otel metadata provider.
             This will automatically include trace and span IDs in log
             messages.
             */
            var handler = StreamLogHandler.standardOutput(label: label, metadataProvider: .otel)
            handler.logLevel = .trace
            return handler
        }

        // MARK: - Bootstrap OTel

        // We use swift-otel's GRPC exporter to send spans to an OTel collector.
        let exporter = OtlpGRPCSpanExporter(config: .init(eventLoopGroup: eventLoopGroup))

        // This span processor will create batches of spans and then forwards these batches
        // to the exporter.
        let processor = OTel.BatchSpanProcessor(exportingTo: exporter, eventLoopGroup: eventLoopGroup)

        // Finally, the main OTel class ties everything together.
        let otel = OTel(serviceName: "example", eventLoopGroup: eventLoopGroup, processor: processor)

        // When started, OTel will discover resource attributes.
        try otel.start().wait()

        /*
         Once started, we can bootstrap the instrumentation system to use our tracer.

         The instrumentation system works similar to the LoggingSystem or MetricsSystem.
         Once bootstrapped, all compatible libraries will automatically use it to instrument
         your application.
         */
        InstrumentationSystem.bootstrap(otel.tracer())

        return otel
    }
}
