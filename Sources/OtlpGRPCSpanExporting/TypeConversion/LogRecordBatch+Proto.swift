//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest {
    init<C: Collection>(_ batch: C) where C.Element == OTel.LogRecord {
        self = .with { request in
            request.resourceLogs = batch.reduce(into: []) { r, logRecord in
                r.append(.with { resourceLogs in
                    resourceLogs.resource = .init(.init(attributes: [
                        "service.name": "onboarding",
                    ]))
                    resourceLogs.scopeLogs = [
                        .with {
                            $0.scope = .with { _ in }
                            $0.logRecords = [.init(logRecord)]
                        },
                    ]
                })
            }
        }
    }
}
