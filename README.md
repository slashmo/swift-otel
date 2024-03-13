# Swift OTel

An [OpenTelemetry](https://opentelemetry.io) client for server-side Swift.

[![codecov](https://codecov.io/gh/slashmo/swift-otel/graph/badge.svg?token=CLBHHQITUY)](https://codecov.io/gh/slashmo/swift-otel)

## Examples

Swift OTel comes with a couple examples to demonstrate how to get started and how to get beyond the basics:

### Example 1: [Counter](./Examples/Counter)

This example contains an endless running service that keeps counting up a number after a randomized delay.
The increments are traced and exported to [Jaeger](https://jaegertracing.io).

### Example 2: [Server](./Examples/Server)

An example HTTP server built using [Hummingbird](https://github.com/hummingbird-project/hummingbird) and its middleware
for Metrics and Distributed Tracing. Each incoming request is automatically instrumented with a span and metrics such
as the request duration are recorded. Both metrics and traces are sent to an OTel Collector via Swift OTel.
