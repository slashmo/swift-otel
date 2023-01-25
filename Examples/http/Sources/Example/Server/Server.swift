import ArgumentParser
import Foundation
import Hummingbird
import HummingbirdFoundation
import Lifecycle
import LifecycleNIOCompat
import Logging
import NIO
import OpenTelemetry
import OtlpGRPCSpanExporting
import Tracing

struct Server: ParsableCommand {
    @Option private var hostname = "localhost"
    @Option private var port = 8080

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
            serviceName: "server",
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

        let app = HBApplication(
            configuration: .init(address: .hostname(self.hostname, port: self.port), serverName: "ExampleServer"),
            eventLoopGroupProvider: .shared(eventLoopGroup),
            serviceLifecycleProvider: .shared(lifecycle)
        )
        app.decoder = JSONDecoder()
        app.encoder = JSONEncoder()
        app.db = Database()
        app.middleware.add(HBTracingMiddleware(recordingHeaders: ["content-type", "x-forwarded-for"]))
        app.middleware.add(SyncMiddleware())

        app.router.post("/users") { request in
            let payload = try request.decode(as: CreateUserRequest.self)
            return try await request.db.createUser(name: payload.name)
        }

        app.router.get("/users/:id") { request in
            let id = try request.parameters.require("id", as: UUID.self)
            do {
                return try await request.db.user(byID: id)
            } catch DatabaseError.userNotFound {
                throw HBHTTPError(.notFound)
            } catch {
                throw HBHTTPError(.internalServerError)
            }
        }

        try lifecycle.startAndWait()
    }
}

struct CreateUserRequest: Codable {
    let name: String
}

extension User: HBResponseCodable {}

extension UUID: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(uuidString: description)
    }
}

struct SyncMiddleware: HBMiddleware {
    func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        request.eventLoop.submit { }.flatMap { next.respond(to: request) }
    }
}
