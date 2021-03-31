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

extension Opentelemetry_Proto_Trace_V1_ResourceSpans {
    init<C: RandomAccessCollection>(resource: OTel.Resource, spans: C) where C.Element == OTel.RecordedSpan {
        self = .with { resourceSpans in
            resourceSpans.resource = .init(resource)
            resourceSpans.instrumentationLibrarySpans = [.with {
                $0.instrumentationLibrary = .with { library in
                    library.name = "opentelemetry-swift"
                    library.version = OTel.versionString
                }
                $0.spans = spans.map(Opentelemetry_Proto_Trace_V1_Span.init)
            }]
        }
    }
}
