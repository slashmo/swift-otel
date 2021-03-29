//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2021 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO

/// A resource detector asynchronously detects attributes describing an `OTel.Resource`.
///
/// - SeeAlso: [OTel Spec: Resource Creation](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/resource/sdk.md#resource-creation)
public protocol OTelResourceDetector {
    /// Detect attributes describing the returned resource using this detector.
    /// If the detector does not detect any attributes, it returns an empty `OTel.Resource`.
    ///
    /// - Returns: A future `Otel.Resource`
    func detect() -> EventLoopFuture<OTel.Resource>
}

public extension OTel {
    typealias ResourceDetector = OTelResourceDetector
}
