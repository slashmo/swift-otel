# Swift OTel

An [OpenTelemetry](https://opentelemetry.io) client for server-side Swift.

[![codecov](https://codecov.io/gh/slashmo/swift-otel/graph/badge.svg?token=CLBHHQITUY)](https://codecov.io/gh/slashmo/swift-otel)

## Examples

Swift OTel comes with a couple examples to demonstrate how to get started and how to get beyond the basics:

### Example 1: [Counter](./Examples/Counter)

This example contains an endless running service that keeps counting up a number after a randomized delay.
The increments are traced and exported to [Jaeger](https://jaegertracing.io).
