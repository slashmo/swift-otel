# ``OpenTelemetry``

@Options {
    @TopicsVisualStyle(hidden)
}

An OpenTelemetry client for server-side Swift.

## Context Propagation

@Links(visualStyle: list) {
    - ``OTelTraceID``
    - ``OTelSpanID``
    - ``OTelTraceFlags``
    - ``OTelTraceState``
}

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
    - ``OTelSpanID``
    - ``OTelFinishedSpan``
}

### Export

@Links(visualStyle: list) {
    - ``OTelSpanExporter``
    - ``OTelNoOpSpanExporter``    
}

## Configuration

@Links(visualStyle: list) {
    - ``OTelEnvironment``
    - ``OTelEnvironmentValueError``
}

## Topics

### Tracing

- ``OTelSpan``
- ``OTelFinishedSpan``
- ``OTelSpanExporter``
- ``OTelNoOpSpanExporter``
- ``OTelMultiplexSpanExporter``
- ``OTelSpanExporterAlreadyShutDownError``

### Context

- ``OTelTraceID``
- ``OTelSpanID``
- ``OTelTraceFlags``
- ``OTelTraceState``

### Configuration

- ``OTelEnvironment``
- ``OTelEnvironmentValueError``

### Misc

- ``OTelLibrary``
- ``OTelSignal``
