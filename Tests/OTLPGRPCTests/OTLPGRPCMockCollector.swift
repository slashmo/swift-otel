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

import Dispatch
import GRPC
import Logging
import NIO
import NIOConcurrencyHelpers
import NIOHPACK
import OTLPGRPC
import XCTest

final class OTLPGRPCMockCollector: Sendable {
    let metricsProvider = MetricsServiceProvider()
    let traceProvider = TraceServiceProvider()

    @discardableResult
    func withServer<T>(operation: (String) async throws -> T) async throws -> T {
        let server = try await Server.insecure(group: MultiThreadedEventLoopGroup.singleton)
            .withLogger(Logger(label: String(describing: type(of: self))))
            .withServiceProviders([
                metricsProvider,
                traceProvider,
            ])
            .bind(host: "localhost", port: 0)
            .get()

        do {
            let port = try XCTUnwrap(server.channel.localAddress?.port)
            let result = try await operation("http://localhost:\(port)")
            try await server.close().get()
            return result
        } catch {
            try await server.close().get()
            throw error
        }
    }
}

struct RecordedRequest<ExportRequest>: Sendable where ExportRequest: Sendable {
    let exportRequest: ExportRequest
    let context: GRPCAsyncServerCallContext
    var headers: HPACKHeaders { context.request.headers }
}

final class TraceServiceProvider: Sendable, Opentelemetry_Proto_Collector_Trace_V1_TraceServiceAsyncProvider {
    typealias ExportRequest = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest
    typealias ExportResponse = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceResponse

    private let recordedRequestsBox: NIOLockedValueBox<[RecordedRequest<ExportRequest>]> = .init([])
    var requests: [RecordedRequest<ExportRequest>] {
        get { recordedRequestsBox.withLockedValue { $0 } }
        set { recordedRequestsBox.withLockedValue { $0 = newValue } }
    }

    func export(request: ExportRequest, context: GRPCAsyncServerCallContext) async throws -> ExportResponse {
        requests.append(RecordedRequest(exportRequest: request, context: context))
        return ExportResponse()
    }
}

final class MetricsServiceProvider: Sendable, Opentelemetry_Proto_Collector_Metrics_V1_MetricsServiceAsyncProvider {
    typealias ExportRequest = Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest
    typealias ExportResponse = Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceResponse

    private let recordedRequestsBox: NIOLockedValueBox<[RecordedRequest<ExportRequest>]> = .init([])
    var requests: [RecordedRequest<ExportRequest>] {
        get { recordedRequestsBox.withLockedValue { $0 } }
        set { recordedRequestsBox.withLockedValue { $0 = newValue } }
    }

    func export(request: ExportRequest, context: GRPCAsyncServerCallContext) async throws -> ExportResponse {
        requests.append(RecordedRequest(exportRequest: request, context: context))
        return ExportResponse()
    }
}

/// This _used_ to be in the generated code, but not with latest versions of swift-protobuf/grpc-swift plugins.
///
/// The only thing stopping them being Sendable is the `unknownFields: SwiftProtobuf.UnknownStorage` property, which has
/// the following TODO in the swift-protobuf repo:
///
/// > `UnknownStorage` should be `Sendable` but we cannot do so yet without possibly breaking compatibility.
///
/// We'll workaround this by marking things as sendable here until that is addressed.
#if swift(>=5.5) && canImport(_Concurrency)
    extension Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest: @unchecked Sendable {}
    extension Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceResponse: @unchecked Sendable {}
    extension Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsPartialSuccess: @unchecked Sendable {}
    extension Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest: @unchecked Sendable {}
    extension Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceResponse: @unchecked Sendable {}
    extension Opentelemetry_Proto_Collector_Trace_V1_ExportTracePartialSuccess: @unchecked Sendable {}
#endif // swift(>=5.5) && canImport(_Concurrency)
