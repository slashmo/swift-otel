# Swift OTel

An [OpenTelemetry](https://opentelemetry.io) client for server-side Swift.

## Examples

Swift OTel comes with a couple examples to demonstrate how to get started and how to get beyond the basics:

### Example 1: [Basic](./Examples/Basic)

This example contains an endless running service that keeps counting up a number after a randomized delay.
The increments are traced and exported to [Jaeger](https://jaegertracing.io).
