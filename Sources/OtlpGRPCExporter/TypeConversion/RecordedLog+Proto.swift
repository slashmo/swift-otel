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

extension Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest {
    init<C: Collection>(_ batch: C) where C.Element == OTel.RecordedLog {
        self = .with { request in
            request.resourceLogs = batch.reduce(into: []) { r, log in
                let logResource = Opentelemetry_Proto_Resource_V1_Resource(log.resource)
                if let existingIndex = r.firstIndex(where: { $0.resource == logResource }) {
                    r[existingIndex].scopeLogs[0].logRecords.append(.init(log))
                } else {
                    r.append(.with {
                        $0.resource = logResource
                        $0.scopeLogs = [.init(logs: [log])]
                    })
                }
            }
        }
    }
}
