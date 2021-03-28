# OpenTelemetry for Swift
## Basic Example

This is minimal example of how to configure and start `OTel` by using the given defaults.
It leverages [`ServiceLifecycle`](https://github.com/swift-server/swift-service-lifecycle) to invoke `start` and `shutdown`.

## Run

### Using Swift 🐦

Inside this example's directory, simply run `swift run`.

### Using Docker 🐳

Inside the **root directory** of this repository, build and run a docker image for this example:

```sh
docker build -t opentelemetry-examples-basic -f Examples/Basic/Dockerfile .
docker run --rm opentelemetry-examples-basic
```
