import OpenTelemetry
import OtlpGRPCExporter
import Logging
import NIO

@main struct Run {
    static func main() async throws {
        guard #available(macOS 13, *) else {
            fatalError("Old version")
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let exporter = OtlpGRPCExporter(config: .init(eventLoopGroup: group, host: "simplest-collector.monitoring.svc.cluster.local"))
        let otel = OTel(
            serviceName: "nl.orlandos.test",
            eventLoopGroup: group,
            logProcessor: OTel.SimpleLogProcessor(exporter: exporter)
        )
        LoggingSystem.bootstrap { _ in
            otel.logHandler(logLevel: .trace)
        }
        
        let logger = Logger(label: "nl.orlandos.counter")
        var i = 0
        
        while true {
            i += 1
            try await Task.sleep(nanoseconds: 1_000_000_000)
            logger.info("Iteration \(i)")
        }
    }
}
