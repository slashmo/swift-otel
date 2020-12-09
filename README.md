# OpenTelemetry Swift

[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-ED523F.svg?style=flat)](https://swift.org/download/)
[![Continuous Integration](https://github.com/slashmo/opentelemetry-swift/workflows/CI/badge.svg)](https://github.com/slashmo/opentelemetry-swift/actions?query=workflow%3ACI)

## Contributing

Please make sure to run the `./scripts/sanity.sh` script when contributing, it checks formatting and similar things.

You can ensure it always runs and passes before you push by installing a pre-push hook with git:

```sh
echo './scripts/sanity.sh' > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```
