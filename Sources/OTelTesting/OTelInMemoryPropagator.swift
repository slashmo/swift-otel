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
import OpenTelemetry

public final class OTelInMemoryPropagator: OTelPropagator {
    public private(set) var injectedSpanContexts = [OTelSpanContext]()
    public private(set) var extractedCarriers = [Any]()
    private let extractionResult: Result<OTelSpanContext, Error>?

    public init(extractionResult: Result<OTelSpanContext, Error>? = nil) {
        self.extractionResult = extractionResult
    }

    public func inject<Carrier, Inject>(
        _ spanContext: OTelSpanContext,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Injector {
        injectedSpanContexts.append(spanContext)
    }

    public func extractSpanContext<Carrier, Extract>(
        from carrier: Carrier,
        using extractor: Extract
    ) throws -> OTelSpanContext? where Carrier == Extract.Carrier, Extract: Extractor {
        extractedCarriers.append(carrier)
        switch extractionResult {
        case .success(let spanContext): return spanContext
        case .failure(let error): throw error
        case nil: return nil
        }
    }
}
