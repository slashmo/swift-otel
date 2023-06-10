# ``OpenTelemetry``

@Options {
    @TopicsVisualStyle(hidden)
}

An OpenTelemetry client for server-side Swift.

## Distributed Tracing

Distributed tracing support in `OpenTelemetry` is implemented
on top of [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing).
This means any library implementing Swift Distributed Tracing will automatically export traces 
using OpenTelemetry.

@Image(source: "tracing-card", alt: "An illustration of a distributed trace.") {
    An illustration showing a single trace comprised of 5 spans.
}

### Span

@Links(visualStyle: list) {
    - ``OTelSpan``
    - ``OTelFinishedSpan``
}

### Export

@Links(visualStyle: list) {
    - ``OTelSpanExporter``
    - ``OTelNoOpSpanExporter``    
}

## Topics

### Tracing

- ``OTelSpan``
- ``OTelFinishedSpan``
- ``OTelSpanExporter``
- ``OTelNoOpSpanExporter``
- ``OTelMultiplexSpanExporter``
- ``OTelSpanExporterAlreadyShutDownError``
