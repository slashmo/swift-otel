import ArgumentParser
import AsyncHTTPClient
import Foundation
import Lifecycle
import LifecycleNIOCompat
import Logging
import NIO
import NIOHTTP1
import OpenTelemetry
import OtlpGRPCSpanExporting
import Tracing

struct Client: ParsableCommand {
    @Option private var name: String

    func run() throws {
        LoggingSystem.bootstrap({ label, _ in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return handler
        }, metadataProvider: .otel)

        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        let lifecycle = ServiceLifecycle()

        lifecycle.registerShutdown(label: "EventLoopGroup", .async(eventLoopGroup.shutdownGracefully))

        let otel = OTel(
            serviceName: "client",
            eventLoopGroup: eventLoopGroup,
            processor: OTel.BatchSpanProcessor(
                exportingTo: OtlpGRPCSpanExporter(config: .init(eventLoopGroup: eventLoopGroup)),
                eventLoopGroup: eventLoopGroup
            )
        )

        lifecycle.register(
            label: "OTel",
            start: .eventLoopFuture {
                otel.start().always { result in
                    guard case .success = result else { return }
                    InstrumentationSystem.bootstrap(otel.tracer())
                }
            },
            shutdown: .eventLoopFuture(otel.shutdown)
        )

        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        lifecycle.registerShutdown(label: "HTTPClient", .async(client.shutdown))

        lifecycle.register(
            label: "Example",
            start: .sync { [lifecycle] in
                Task.detached {
                    try await InstrumentationSystem.tracer.withSpan(
                        "Create and fetch user",
                        ofKind: .internal
                    ) { span in
                        let logger = Logger(label: "example")
                        let createdUser = try await createUser(client: client)
                        let fetchedUser = try await fetchUser(byID: createdUser.id, client: client)
                        logger.info(
                            "Finished creating and fetching the user.",
                            metadata: [
                                "id": "\(fetchedUser.id)",
                                "name": "\(fetchedUser.name)",
                            ]
                        )
                        span.attributes["user.id"] = "\(fetchedUser.id)"
                    }

                    try await Task.sleep(nanoseconds: 10_000_000_000)
                    lifecycle.shutdown()
                }
            },
            shutdown: .none
        )

        try lifecycle.startAndWait()
    }

    private func createUser(client: HTTPClient) async throws -> UserResponse {
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        var request = try HTTPClient.Request(
            url: "http://localhost:8080/users",
            method: .POST,
            headers: headers
        )
        let jsonEncoder = JSONEncoder()
        let payload = CreateUserPayload(name: "Moritz")
        let bodyData = try jsonEncoder.encode(payload)
        request.body = .bytes(bodyData)

        let response = try await client.executeTraced(&request)
        guard var responseBody = response.body else { fatalError() }
        guard let userResponse = try responseBody.readJSONDecodable(
            UserResponse.self,
            length: responseBody.readableBytes
        ) else { fatalError() }

        return userResponse
    }

    private func fetchUser(byID id: UUID, client: HTTPClient) async throws -> UserResponse {
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        var request = try HTTPClient.Request(
            url: "http://localhost:8080/users/\(id)",
            method: .GET,
            headers: headers
        )
        let response = try await client.executeTraced(&request)

        guard var responseBody = response.body else { fatalError() }
        guard let userResponse = try responseBody.readJSONDecodable(
            UserResponse.self,
            length: responseBody.readableBytes
        ) else { fatalError() }

        return userResponse
    }
}

struct HTTPHeadersInjector: Injector {
    func inject(_ value: String, forKey name: String, into headers: inout HTTPHeaders) {
        headers.add(name: name, value: value)
    }
}

struct CreateUserPayload: Encodable {
    let name: String
}

struct UserResponse: Decodable {
    let id: UUID
    let name: String
}

extension HTTPClient {
    func executeTraced(_ request: inout Request) async throws -> Response {
        try await InstrumentationSystem.tracer.withSpan("HTTP POST", ofKind: .client) { span in
            span.attributes["http.method"] = request.method.rawValue
            span.attributes["http.url"] = "\(request.url)"
            span.attributes["net.peer.name"] = request.host
            span.attributes["net.peer.port"] = request.port

            InstrumentationSystem.instrument.inject(
                span.baggage,
                into: &request.headers,
                using: HTTPHeadersInjector()
            )

            span.attributes["http.request_content_length"] = request.body?.length

            let response = try await execute(request: request).get()
            span.attributes["http.flavor"] = "\(response.version.major).\(response.version.minor)"
            span.attributes["http.status_code"] = Int(response.status.code)
            span.attributes["http.response_content_length"] = response.body?.readableBytes
            if 400 ..< 500 ~= response.status.code {
                span.setStatus(.init(code: .error))
            }

            return response
        }
    }
}
