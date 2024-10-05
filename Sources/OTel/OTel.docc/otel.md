# ``OTel``

@Metadata {
    @DisplayName("Swift OTel")
    @PageImage(purpose: icon, source: "otel-logo")
}

An OpenTelemetry client for server-side Swift.

## Glossary

| Term | Meaning |
| --- | --- |
| OpenTelemetry | The [OpenTelemetry](https://opentelemetry.io) project |
| Swift OTel | This library, a Swift client for OpenTelemetry |

## Overview

OpenTelemetry supports three instrumentation signals, which all happen to have great foundational libraries used
throughout the server-side Swift ecosystem.
The goal of Swift OTel is to support all three in a way that feels right at home.

@Links(visualStyle: compactGrid) {
    - <doc:logging>
    - <doc:metrics>
    - <doc:tracing>
}

### Implementation Status

| Signal | Swift Library | Swift OTel Support | 
| --- | --- | --- |
| <doc:logging> | [swift-log](https://github.com/apple/swift-log) | 🏗️ |
| <doc:metrics> | [swift-metrics](https://github.com/apple/swift-metrics) | ✅ |
| <doc:tracing> | [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing) | ✅ |

## Installation

First, add the following snippet to the `dependencies` section of your `Package.swift` file:

```swift
.package(url: "https://github.com/slashmo/swift-otel.git", branch: "main"),
```

Then, add a dependency on `OTel` in your target that sets up Swift OTel: 

```swift
.product(name: "OTel", package: "swift-otel"),
```

## Sample Code

@Links(visualStyle: detailedGrid) {
    - <doc:counter-sample>
    - <doc:server-sample>
}

## Topics

### Signals

- <doc:logging>
- <doc:metrics>
- <doc:tracing>

### Resource Detection

- <doc:resource-detection>
- ``OTelResource``
- ``OTelResourceDetection``
- ``OTelEnvironmentResourceDetector``
- ``OTelProcessResourceDetector``
- ``OTelResourceDetector``

### Log Correlation

- <doc:log-correlation>
- ``Logging/Logger/MetadataProvider``

### Sample Code

- <doc:counter-sample>
- <doc:server-sample>

### Misc

- ``OTelLibrary``
- ``OTelEnvironment``
- ``OTelEnvironmentValueError``
