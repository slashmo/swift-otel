import OpenTelemetry
import OtlpGRPCExporter
import Logging
import Metrics
import NIO

@main struct Run {
    static func main() async throws {
        guard #available(macOS 13, *) else {
            fatalError("Old version")
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let exporter = OtlpGRPCExporter(config: .init(eventLoopGroup: group, host: "simplest-collector.monitoring.svc.cluster.local"))
        let otel = OTel(
            serviceName: "orlandos_test",
            eventLoopGroup: group,
            metricsProcessor: OTel.SimpleMetricsProcessor(exporter: exporter),
            logProcessor: OTel.SimpleLogProcessor(exporter: exporter)
        )
        LoggingSystem.bootstrap { _ in
            otel.logHandler(logLevel: .trace)
        }
        MetricsSystem.bootstrap(otel.metricsFactory())
        
        // Keep counting
        Task {
            let timer = MetricsSystem.factory.makeCounter(label: "orlandos_counter_total", dimensions: [])
            
            while true {
                timer.increment(by: .random(in: 1..<3))
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        // Fluctuate between 10 and 255ms latency
        Task {
            let recorder = MetricsSystem.factory.makeRecorder(label: "orlandos_random_latency_total", dimensions: [], aggregate: false)
            
            while true {
                recorder.record(Double.random(in: 10..<255))
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        // Fluctuate between UInt8
        Task {
            let timer = MetricsSystem.factory.makeTimer(label: "orlandos_sleep_timer_total", dimensions: [])
            
            while true {
                let sleep = Int64.random(in: 1_000_000 ..< 1_000_000_000)
                
                timer.recordNanoseconds(sleep)
                try await Task.sleep(nanoseconds: .init(sleep))
            }
        }
        
        let logger = Logger(label: "nl_sorlandos_counter")
        var i = 0
        while true {
            i += 1
            try await Task.sleep(nanoseconds: 1_000_000_000)
            logger.info("Iteration \(i)")
        }
    }
}
