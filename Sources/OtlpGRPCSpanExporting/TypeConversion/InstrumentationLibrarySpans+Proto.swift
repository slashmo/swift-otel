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

extension Opentelemetry_Proto_Trace_V1_InstrumentationLibrarySpans {
    init<C: Collection>(spans: C) where C.Element == OTel.RecordedSpan {
        self = .with {
            $0.instrumentationLibrary = .with { library in
                library.name = "swift-otel"
                library.version = OTel.versionString
            }
            $0.spans = spans.map(Opentelemetry_Proto_Trace_V1_Span.init)
        }
    }
}
