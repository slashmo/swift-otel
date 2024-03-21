
/*
 API
 --

 SDK
 --
 MeterProviders can be used to get a Meter
 Meters can be used to create instruments
 Instruments create measurements
 MetricReaders collect metrics
 MetricReaders need an exporter, default aggregation, default temporality, optional filter, etc.
 MetricExporters export metrics
 Metric exporters always have an associated reader, this is how it determinse the temporaility and aggregration
 Metirc exporters have access to the aggregated metrics data

 DataModel
 --
 Event model covers how instruments report metric data
 Timeseries model covers how backends store the data
 Metric stream model (OTLP) covers how metric data streams are manipulated and transmitted between the event model and timeseries storage.
 Metric points are points in the data stream: they can be one of sum, gauge, histogram etc.


 */


/*
import Foundation
import ServiceLifecycle
import AsyncAlgorithms


public enum OTelInstrumentObservation {

}

// TODO: what's the name it uses in the spec?
public protocol OTelMetricIdentifiable {
    associatedtype Identity: Hashable
    var identity: Identity { get }
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#meterprovider
public struct OTelMeterProvider {
    var resource: OTelResource
    var views: [OTelMetricView]
    var readers: [OTelMetricReader]

    var meters: [OTelMeter.Identity: OTelMeter]

    var eventStream: AsyncStream<Event>
    var eventStreamContinuation: AsyncStream<Event>.Continuation


    enum Event {
        case incrementCounter(_ counter: OTelCounter, by: Int, attributes: [OTelAttribute])
    }


    // TODO: add view property
    public func meter(
        name: String,
        version: String? = nil,
        schemaURL: String? = nil,
        attributes: [OTelAttribute]
    ) -> OTelMeter {
        OTelMeter(
            name: name,
            version: version,
            schemaURL: schemaURL,
            attributes: attributes,
            counters: [:]
        )
    }
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/api.md#meter
public struct OTelMeter: OTelMetricIdentifiable {
    var name: String
    var version: String?
    var schemaURL: String?
    var attributes: [OTelAttribute]
//    var readers: [OTelMetricReader]

    public var identity: some Hashable { name }  // TODO

    var counters: [OTelCounter.Identity: OTelCounter]

    // https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/api.md#counter-creation
    func counter(
        name: String,
        unit: String?,
        description: String?
    ) -> OTelCounter {
        OTelCounter(
            name: name,
            unit: unit,
            description: description
        )
    }

}

public enum OTelInstrumentKind {
    case counter
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/api.md#instrument
public protocol OTelInstrument: OTelMetricIdentifiable {
    var name: String { get }
    var kind: OTelInstrumentKind { get }
    var unit: String? { get }
    var description: String? { get }
}

public extension OTelInstrument {
    var identity: some Hashable { name }
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/api.md#synchronous-instrument-api
public typealias OTelSynchronousInstrument = OTelInstrument

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/api.md#asynchronous-instrument-api
public protocol OTelAsynchronousInstrument: OTelInstrument {
    var callback: [() -> Void] { get }
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/api.md#counter
public final class OTelCounter: OTelSynchronousInstrument {
    public var name: String
    public let kind = OTelInstrumentKind.counter
    public var unit: String?
    public var description: String?

    init(name: String, unit: String? = nil, description: String? = nil) {
        self.name = name
        self.unit = unit
        self.description = description
    }

    struct Event {
        var amount: Int
        var attributes: [OTelAttribute]
    }


    // https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/api.md#add
    func add(_ amount: Int, attributes: [OTelAttribute] = []) {

//        self.eventContinuation.yield(Event(amount: amount, attributes: attributes))
    }
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/sdk.md#aggregation
public enum OTelAggregation {
    case drop
    case `default`
    case sum
    case lastValue
    case explicitBucketHistogram
    case base2ExponentialBucketHistogram
}

public enum OTelTemporality {
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/sdk.md#metricreader
// The SDK MUST NOT allow a MetricReader instance to be registered on more than one MeterProvider instance.
// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/metrics/sdk.md#metricreader-operations
public protocol OTelMetricReader {
    var defaultAggregation: [OTelInstrumentKind: OTelAggregation] { get }
    var defaultTemporaility: [OTelInstrumentKind: OTelTemporality] { get }
    var exporter: OTelMetricExporter { get }

    // The MetricReader.Collect method allows general-purpose MetricExporter instances to explicitly initiate collection, commonly used with pull-based metrics collection. A common sub-class of MetricReader, the periodic exporting MetricReader SHOULD be provided to be used typically with push-based metrics collection.
    func collect() -> [OTelMetricPoint]

    func shutdown()
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#periodic-exporting-metricreader
public struct OTelPeriodicExportingMetricReader: OTelMetricReader {
    public var defaultAggregation: [OTelInstrumentKind: OTelAggregation] = [:]
    public var defaultTemporaility: [OTelInstrumentKind: OTelTemporality] = [:]
    public var exporter: OTelMetricExporter

    var exportIntervalMillis: Int = 60_000
    var exportTimeoutMillis: Int = 30_000

    public func collect() -> [OTelMetricPoint] {
        fatalError("\(#function) not implemented")
    }

    public func shutdown() {
        fatalError("\(#function) not implemented")
    }

    // https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#forceflush-1
    func forceFlush() {
        // collect metrics
        // call export(batch) and forceflush() on the push metric exporter
    }

    public func run() async throws {
        let timerEvents = AsyncTimerSequence(interval: .milliseconds(exportIntervalMillis), clock: .suspending).cancelOnGracefulShutdown() // TODO: Clock param
        for try await _ in timerEvents {
            try await withTimeout(.milliseconds(exportTimeoutMillis)) {
                let batch = self.collect()
                try await exporter.export(batch)
            }
        }
        await exporter.shutdown()
    }
}


/*
// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#metricexporter
protocol OTelMetricExporter: Sendable {
    var reader: OTelMetricReader { get }
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#push-metric-exporter
protocol OTelPushMetricExporter: OTelMetricExporter {
    // https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#exportbatch
    func export(_ batch: [OTelMetricPoint]) -> OTelResult

    // https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#forceflush-2
    func forceFlush() -> OTelResult

    // https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#shutdown-2
    func shutdown()
}
 */

public enum OTelResult {
    case success
    case failure
    case timeout
}


// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#metricproducer
public protocol MetricProducer {
    // https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#produce-batch
    func produce(filter: OTelMetricFilter?)
}

// https://github.com/open-telemetry/opentelemetry-specification/blob/v1.29.0/specification/metrics/sdk.md#metricfilter
public struct OTelMetricFilter {
}

public struct OTelMetricView {
}
*/
