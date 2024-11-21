# Distributed Tracing

@Metadata {
    @TitleHeading("Signal")
    @PageImage(purpose: card, source: "tracing-card", alt: "An illustration of a distributed trace.")
    @PageColor(orange)
    @Available("Swift OTel", introduced: "1.0")
}

OpenTelemetry tracing implemented on top of Swift Distributed Tracing.

## Overview

Distributed tracing support in Swift OTel is implemented on top of the
[Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing) library.
This allows "plug-and-play" like integration with other libraries from the ecosystem, e.g. 
[Hummingbird](https://github.com/hummingbird-project/hummingbird) via its tracing middleware.
As long as these libraries use `swift-distributed-tracing` for their Tracing implementation, you'll be able to process
and export their spans with Swift OTel.

@Image(source: "tracing-card", alt: "An illustration of a distributed trace.") {
    A distributed trace, comprised of multiple spans across two services.
}

## Getting Started

Swift OTel's Distributed Tracing API is comprised of multiple layers.

### Tracer

``OTelTracer`` is the main entrypoint to Distributed Tracing in Swift OTel. We'll cover its dependencies below.

```swift
let tracer = OTelTracer(
    idGenerator: idGenerator,
    sampler: sampler,
    propagator: propagator,
    processor: processor,
    resource: resource
)
```

#### Instrumentation System

Once initialized, bootstrap the `InstrumentationSystem` to use your ``OTelTracer``.

```swift
InstrumentationSystem.bootstrap(tracer)
```

> Tip: You don't need to use ``OTelTracer`` directly to create spans. Instead, transparently use it via the
`InstrumentationSystem`, e.g. by calling `InstrumentationSystem.tracer.withSpan`.

#### Service Lifecycle

``OTelTracer`` also implements the
[`Service`](https://swiftpackageindex.com/swift-server/swift-service-lifecycle/2.6.0/documentation/servicelifecycle/service)
protocol from `swift-service-lifecycle`. Make sure to add the ``OTelTracer`` as early as possible in your service group.
This ensures that spans created during the start of your other services are already properly processed by Swift OTel.

### ID Generator

When creating spans, ``OTelTracer`` generates random trace and span IDs. Most likely, you'll want to
use the default ``OTelRandomIDGenerator``. However, some distributed tracing systems may require different semantics
for these IDs. In this case, you can pass a different ``OTelIDGenerator`` implementation to ``OTelTracer``.

An example
of this is AWS X-Ray, which requires trace IDs to include the current date. In this case,
[`XRayIDGenerator`](https://swiftpackageindex.com/slashmo/swift-otel-xray/0.9.0/documentation/opentelemetryxray/xrayidgenerator)
from [`swift-otel-xray`](https://github.com/slashmo/swift-otel-xray) has you covered.

Custom id generators are implemented by conforming to ``OTelIDGenerator``:

```swift
struct MyGenerator: OTelIDGenerator {
    func nextTraceID() -> TraceID {
        // ... 
    }

    func nextSpanID() -> SpanID {
        // ... 
    }
}
```

### Sampler

When creating new spans, the tracer asks a sampler whether the span should be processed and/or exported. This enables
control over the amount of spans held in-memory for processing and the number of spans exported. 
The simplest sampler in Swift OTel is ``OTelConstantSampler``, which either samples all or no spans.

Sampling decisions are propagated across distributed systems via propagators.
``OTelParentBasedSampler`` allows you take advantage of this.
It delegates the sampling decision to different (configurable) samplers based on the span's parent, e.g. whether
_it_ was sampled:

```swift
let sampler = OTelParentBasedSampler(
    rootSampler: MySampler(),
    remoteParentSampledSampler: OTelConstantSampler(isOn: true),
    remoteParentNotSampledSampler: OTelConstantSampler(isOn: false),
    localParentSampledSampler: OTelConstantSampler(isOn: true),
    localParentNotSampledSampler: OTelConstantSampler(isOn: false)
)
```

You may also implement your own sampler by conforming to ``OTelSampler``:

```swift
struct MySampler: OTelSampler {
    func samplingResult(
        operationName: String,
        kind: SpanKind,
        traceID: TraceID,
        attributes: SpanAttributes,
        links: [SpanLink],
        parentContext: ServiceContext
    ) -> OTelSamplingResult {
        OTelSamplingResult(decision: .recordAndSample)
    }
}
```

### Propagator

Context propagation allows multiple services to contribute spans to a combined trace, thus enabling _distributed_
tracing. The likely choice is ``OTelW3CPropagator``. 
It uses the W3C Trace Context standard, which means that you can easily create traces across multiple services,
no matter whether they're using Swift OTel or not even using Swift at all.

``OTelPropagator`` is built on top of the
[`Instrument`](https://swiftpackageindex.com/apple/swift-distributed-tracing/documentation/instrumentation/instrument)
type from `swift-distributed-tracing`. This means any server-side Swift libraries will transparently invoke the
configured propagator anywhere they inject/extract `ServiceContext` to/from a given carrier.

You may also implement custom propagators by conforming to ``OTelPropagator`` and use multiple propagators at once
via ``OTelMultiplexPropagator``:

```swift
let propagator = OTelMultiplexPropagator([MyPropagator(), OTelW3CPropagator()])

struct MyPropagator: OTelPropagator {
    func extractSpanContext<Carrier, Extract>(
        from carrier: Carrier,
        using extractor: Extract
    ) throws -> OTelSpanContext? where Extract: Extractor, Extract.Carrier == Carrier {
        guard let myValue = extractor.extract(key: "my-key"),
              let traceContext = TraceContext(myDecoding: myValue) else { return nil }

        return .remote(traceContext: traceContext)
    }

    func inject<Carrier, Inject>(
        _ spanContext: OTelSpanContext,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Inject: Injector, Inject.Carrier == Carrier {
        injector.inject(spanContext.myValue, forKey: "my-key", into: &carrier)
    }
}
``` 

### Processor

Span processors are invoked twice during the lifetime of a span. Once when the span is started and once when it's ended.
The recommended span processor is ``OTelBatchSpanProcessor``, which collects batches of spans and sends them to an
exporter.

```swift
let processor = OTelBatchSpanProcessor(
    exporter: exporter,
    configuration: OTelBatchSpanProcessorConfiguration(environment: environment)
)
```

Multiple span processors may be combined using ``OTelMultiplexSpanProcessor``, and custom processors can be implemented
by conforming ``OTelSpanProcessor``:

```swift
let processor = OTelMultiplexSpanProcessor([
    OTelBatchSpanProcessor(
        exporter: exporter,
        configuration: OTelBatchSpanProcessorConfiguration(environment: environment)
    ),
    MySpanProcessor()
])

struct MySpanProcessor: OTelSpanProcessor {
    func onStart(_ span: OTelSpan, parentContext: ServiceContext) async {
        // here, we may mutate any mutable properties of the span
        span.attributes["foo"] = "bar"
    }

    func onEnd(_ span: OTelFinishedSpan) async {
        // here, we may want to forward the finished (immutable) span to an exporter
        await exporter.export(span)
    }

    // ...
}
```

> Tip: Span processors don't necesarilly have to forward processed spans to an exporter. You can also use them to just
> mutate spans when they're started, e.g. dynamically add attributes based on existing properties of the span.

### Resource

All spans created by an ``OTelTracer`` belong to a single "resource". This resource contains information such as your
service's name, and will be sent along when exporting spans using Swift OTel.

You can either create this ``OTelResource`` manually or use resource detection as shown here:

@Links(visualStyle: list) {
    - <doc:resource-detection>
}

### Exporter

Span exporters are the final piece to the puzzle, sending spans to a distributed tracing platform. Exporters are not
passed directly to the tracer but to a span processor. This allows batching of spans (see ``OTelBatchSpanProcessor``)
before exporting.

Swift OTel's main exporter is `OTLPGRPCSpanExporter`, which exports spans via gRPC to any OTLP comatible receivers.
`OTLPGRPCSpanExporter` is part of [`OTLPGRPC`](https://swiftpackageindex.com/slashmo/swift-otel/documentation/otlpgrpc),
an additional library included in the `swift-otel` package. You can find its documentation
[here](https://swiftpackageindex.com/slashmo/swift-otel/documentation/otlpgrpc).

Custom exportes may be implemented by conforming to ``OTelSpanExporter`` and multiple exporters may be combined using
``OTelMultiplexSpanExporter``:

```swift
let exporter = OTelMultiplexSpanExporter([
    OTLPGRPCSpanExporter(configuration: OTLPGRPCSpanExporterConfiguration(environment: environment)),
    MySpanExporter()
])

struct MyExporter: OTelSpanExporter {
    func export(_ batch: some Collection<OTelFinishedSpan> & Sendable) async throws {
        print(batch)
    }
    
    // ...
}
```

## Integrations

@Links(visualStyle: detailedGrid) {
    - <doc:log-correlation>
}

## Sample Code

A collection of Swift OTel examples that make use of Distributed Tracing.

@Links(visualStyle: detailedGrid) {
    - <doc:counter-sample>
    - <doc:server-sample>
}

## Topics

### Tracing

- ``OTelTracer``
- ``OTelSpan``

### Processing Spans

- ``OTelSpanProcessor``
- ``OTelBatchSpanProcessor``
- ``OTelBatchSpanProcessorConfiguration``
- ``OTelSimpleSpanProcessor``
- ``OTelMultiplexSpanProcessor``
- ``OTelNoOpSpanProcessor``
- ``OTelFinishedSpan``

### Exporting Spans

- ``OTelSpanExporter``
- ``OTelMultiplexSpanExporter``
- ``OTelNoOpSpanExporter``
- ``OTelSpanExporterAlreadyShutDownError``

### Sampling Spans

- ``OTelSampler``
- ``OTelSamplingResult``
- ``OTelParentBasedSampler``
- ``OTelConstantSampler``

### Generating IDs

- ``OTelIDGenerator``
- ``OTelRandomIDGenerator``

### Propagating Context

- ``OTelSpanContext``
- ``ServiceContextModule/ServiceContext``
- ``OTelPropagator``
- ``OTelW3CPropagator``
- ``OTelMultiplexPropagator``
