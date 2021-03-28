# OpenTelemetry for Swift

[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-%23f05137)](https://swift.org)
[![Made for Swift Distributed Tracing](https://img.shields.io/badge/Made%20for-Swift%20Distributed%20Tracing-%23f05137)](https://github.com/apple/swift-distributed-tracing)

Gain insights into your Swift server applications using [OpenTelemetry](https://opentelemetry.io) easily. By
implementing the [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing) API,
[compatible libraries](https://github.com/apple/swift-distributed-tracing#libraries--frameworks) work out of the box.

## Getting Started

[TODO]

### Examples

The [`Examples`](/Examples) directory contains applications highlighting various aspects and use-cases of the library.

## Development

### Formatting

To ensure a consitent code style we use [SwiftFormat](https://github.com/nicklockwood/SwiftFormat). To ensure it runs before you push to GitHub, you may define a `pre-push` Git hook executing the *soundness* script:

```sh
echo './scripts/soundness.sh' > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```
