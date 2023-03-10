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

import OpenTelemetry

extension Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest {
    init<C: Collection>(_ batch: C) where C.Element == OTel.RecordedSpan {
        self = .with { request in
            request.resourceSpans = batch.reduce(into: []) { r, span in
                let spanResource = Opentelemetry_Proto_Resource_V1_Resource(span.resource)
                if let existingIndex = r.firstIndex(where: { $0.resource == spanResource }) {
                    r[existingIndex].scopeSpans[0].spans.append(.init(span))
                }
                r.append(.with { resourceSpans in
                    resourceSpans.resource = spanResource
                    resourceSpans.scopeSpans = [
                        .with {
                            $0.scope = .with { _ in }
                            $0.spans = [.init(span)]
                        },
                    ]
                })
            }
        }
    }
}
