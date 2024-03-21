# Swift OTel Metrics

* What is currently provides is a "backend" for the Swift Tracing, and Swift Log API packages (similar philosophy to the OTel API/SDK split) with an OTLP exporter.
* While the Swift Tracing API and OTel Tracing APIs are a very close match, there's quite some divergence in functionality and expressivity between Swift Metrics and OTel Metrics.
* For this reason, my current opinion is that swift-otel should probably have a narrower focus and explicitly make it a non-goal to be a full OTel API/SDK package.
* Instead it can focus on providing OTLP backends for the Swift Tracing, Swift Metrics, and Swift Log systems.
* It can then keep its API surface and implementation geared toward Swift Server use cases, implementing only the necessary parts to support the subset of OTLP that can be expressed through the Swift frontend APIs.
* The above would create a clear separation of interests and diffuse any concerns about why Apple is or isn't contributing the official SDK in the immediate term.
* In the medium term we can still look to invest in the official SDK by starting to work on the issues above.
