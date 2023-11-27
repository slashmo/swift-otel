//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Instrumentation
import NIOConcurrencyHelpers
import OpenTelemetry

public final class OTelInMemoryPropagator: OTelPropagator, Sendable {
    private let _injectedSpanContexts = NIOLockedValueBox([OTelSpanContext]())
    public var injectedSpanContexts: [OTelSpanContext] { _injectedSpanContexts.withLockedValue { $0 } }

    /*
     Sendable warning fixed in https://github.com/apple/swift-distributed-tracing/pull/136,
     since it enables us to use `NIOLockedValueBox([any Sendable])` instead.
     */
    private let _extractedCarriers = NIOLockedValueBox([Any]())
    public var extractedCarriers: [Any] { _extractedCarriers.withLockedValue { $0 } }
    private let extractionResult: Result<OTelSpanContext, Error>?

    public init(extractionResult: Result<OTelSpanContext, Error>? = nil) {
        self.extractionResult = extractionResult
    }

    public func inject<Carrier, Inject>(
        _ spanContext: OTelSpanContext,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Injector {
        _injectedSpanContexts.withLockedValue { $0.append(spanContext) }
    }

    public func extractSpanContext<Carrier, Extract>(
        from carrier: Carrier,
        using extractor: Extract
    ) throws -> OTelSpanContext? where Carrier == Extract.Carrier, Extract: Extractor {
        _extractedCarriers.withLockedValue { $0.append(carrier) }
        switch extractionResult {
        case .success(let spanContext): return spanContext
        case .failure(let error): throw error
        case nil: return nil
        }
    }
}
