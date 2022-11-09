import OpenTelemetry
import Logging
import NIO

@main struct Run {
    static func main() async throws {
        guard #available(macOS 13, *) else {
            fatalError("Old version")
            
        }
        let otel = OTel(serviceName: "nl.orlandos.test", eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: 1))
        LoggingSystem.bootstrap { _ in
            otel.logHandler(logLevel: .trace)
        }
        
        let logger = Logger(label: "nl.orlandos.counter")
        var i = 0
        
        while true {
            i += 1
            try await Task.sleep(for: .seconds(1))
            logger.info("Iteration \(i)")
        }
    }
}
