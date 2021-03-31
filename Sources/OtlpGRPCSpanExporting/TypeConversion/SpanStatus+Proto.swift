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

import Tracing

extension Opentelemetry_Proto_Trace_V1_Status {
    init(_ spanStatus: SpanStatus) {
        self = Opentelemetry_Proto_Trace_V1_Status.with { status in
            if let message = spanStatus.message {
                status.message = message
            }
            switch spanStatus.code {
            case .ok:
                status.code = .ok
            case .error:
                status.code = .error
            }
        }
    }
}
