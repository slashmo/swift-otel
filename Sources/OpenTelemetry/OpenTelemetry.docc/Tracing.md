# Tracing

A Distributed Tracing implementation for `OpenTelemetry`.

## Overview

Distributed tracing support in `OpenTelemetry` is implemented
on top of [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing). This means any library
implementing Swift Distributed Tracing will automatically export traces using OpenTelemetry.

## Topics

### Span

- ``OTelSpan``
- ``OTelFinishedSpan``

### Export

- ``OTelSpanExporter``
- ``OTelSpanExporterAlreadyShutDownError``
- ``OTelNoOpSpanExporter``
