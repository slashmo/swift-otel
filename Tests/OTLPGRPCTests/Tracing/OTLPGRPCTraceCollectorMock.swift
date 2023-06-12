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
import NIOHPACK
import OTLPGRPC
import XCTest

final class OTLPGRPCTraceCollectorMock {
    var requests: [Request] {
        requestsQueue.sync { _requests }
    }
    private var _requests = [Request]()
    private let requestsQueue = DispatchQueue(label: "requests")

    fileprivate let group: any EventLoopGroup
    fileprivate let logger: Logger

    init(
        group: any EventLoopGroup,
        logger: Logger = Logger(label: String(describing: OTLPGRPCTraceCollectorMock.self))
    ) {
        self.group = group
        self.logger = logger
    }

    @discardableResult
    func withServer<T>(operation: (String) async throws -> T) async throws -> T {
        let server = try await Server.insecure(group: group)
            .withLogger(logger)
            .withServiceProviders([self])
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


    typealias ExportRequest = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest
    typealias ExportResponse = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceResponse

    struct Request {
        let exportRequest: ExportRequest
        let context: GRPCAsyncServerCallContext

        var headers: HPACKHeaders {
            context.request.headers
        }
    }
}

extension OTLPGRPCTraceCollectorMock: Opentelemetry_Proto_Collector_Trace_V1_TraceServiceAsyncProvider {
    func export(request: ExportRequest, context: GRPCAsyncServerCallContext) async throws -> ExportResponse {
        requestsQueue.sync {
            _requests.append(Request(exportRequest: request, context: context))
        }
        return ExportResponse()
    }
}
