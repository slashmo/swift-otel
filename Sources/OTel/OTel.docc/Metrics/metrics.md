# Metrics

@Metadata {
    @TitleHeading("Signal")
    @PageImage(purpose: card, source: "metrics-card", alt: "An illustration of diagrams.")
    @PageColor(purple)
    @Available("Swift OTel", introduced: "1.0")
}

OpenTelemetry metrics implemented on top of Swift Metrics.

## Overview

Metrics support in Swift OTel is implemented on top of the [Swift Metrics](https://github.com/apple/swift-metrics.git)
library. This allows "plug-and-play" like integration with other libraries from the ecosystem, e.g.
[Vapor](https://github.com/vapor/vapor). As long as they support `swift-metrics`, you'll be able to
export their metrics via OpenTelemetry using Swift OTel.

@Image(source: "metrics-card", alt: "An illustration of diagrams.") {
    Two diagrams illustrating how metrics might be visualized.
}

## Getting Started

The metrics API in Swift OTel consists of a couple of layers.

### Metrics Factory

At its core, Swift OTel metrics is implemented as a Swift Metrics
[`MetricsFactory`](https://swiftpackageindex.com/apple/swift-metrics/2.5.0/documentation/coremetrics/metricsfactory).
You'll use this factory to [bootstrap the `MetricsSystem`](https://swiftpackageindex.com/apple/swift-metrics/2.5.0/documentation/coremetrics#Selecting-a-metrics-backend-implementation-applications-only),
Once bootstrapped, any metrics you create manually and the ones your dependencies emit are ready to be exported via
[OTLP](https://opentelemetry.io/docs/specs/otlp/) (OpenTelemetry Protocol).
 
### Metrics Reader

``OTelPeriodicExportingMetricsReader`` periodically reads metrics and forwards them to an ``OTelMetricExporter``.
It also conforms to the
[`Service`](https://swiftpackageindex.com/swift-server/swift-service-lifecycle/2.6.0/documentation/servicelifecycle/service)
protocol from Swift ServiceLifecycle and **must be kept running for the lifetime of your application**.

> See Also: Please read the `OTLPGRPC` documentation to learn about `OTLPGRPCMetricExporter`,
the ``OTelMetricExporter`` implementation sending metrics via gRPC to an OTel collector of choice.   

### Metrics Registry

``OTelMetricRegistry`` acts as the glue between ``OTLPMetricsFactory`` and ``OTelPeriodicExportingMetricsReader``,
storing metrics produced via Swift Metrics in-memory, to be read by the periodic reader and thus exported.

### Complete setup

> Tip: This code snippet assumes two variables: `environment` and `resource`.
> Check out <doc:resource-detection> to learn more about them.

```swift
import OTel
import OTLPGRPC

let registry = OTelMetricRegistry()

// create the periodic reader exporting via gRPC
let reader = OTelPeriodicExportingMetricsReader(
    resource: resource,
    producer: registry,
    exporter: try OTLPGRPCMetricExporter(configuration: .init(environment: environment)),
    configuration: .init(environment: environment)
)

// bootstrap the metrics system
MetricsSystem.bootstrap(OTLPMetricsFactory(registry: registry))

// run the reader as part of your ServiceGroup 
let serviceGroup = ServiceGroup(services: [reader])
try await serviceGroup.run()
```

## Sample Code

A collection of Swift OTel examples that make use of Metrics.

@Links(visualStyle: detailedGrid) {
    - <doc:server-sample>
}

## Topics

- ``OTLPMetricsFactory``
- ``OTelMetricRegistry``
- ``OTelMetricProducer``
- ``OTelPeriodicExportingMetricsReader``
- ``OTelPeriodicExportingMetricsReaderConfiguration``
- ``OTelMetricExporter``
- ``OTelMetricExporterAlreadyShutDownError``
- ``OTelMultiplexMetricExporter``
- ``OTelConsoleMetricExporter``
- ``OTelAggregationTemporality``
- ``OTelAttribute``
- ``OTelGauge``
- ``OTelHistogram``
- ``OTelHistogramDataPoint``
- ``OTelInstrumentationScope``
- ``OTelMetricPoint``
- ``OTelNumberDataPoint``
- ``OTelResourceMetrics``
- ``OTelScopeMetrics``
- ``OTelSum``
