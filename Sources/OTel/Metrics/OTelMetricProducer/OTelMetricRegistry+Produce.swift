//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension OTelMetricRegistry: OTelMetricProducer {
    func produce() -> [OTelMetricPoint] {
        let metrics = storage.withLockedValue { $0 }
        var buffer: [OTelMetricPoint] = []
        buffer.reserveCapacity(1024) // TODO: Make this configurable? Also, does this overlap with OTel "cardinality"?
        for instruments in metrics.counters.values {
            for instrument in instruments.values {
                buffer.append(instrument.measure())
            }
        }
        for instruments in metrics.gauges.values {
            for instrument in instruments.values {
                buffer.append(instrument.measure())
            }
        }
        for instruments in metrics.durationHistograms.values {
            for instrument in instruments.values {
                buffer.append(instrument.measure())
            }
        }
        for instruments in metrics.valueHistograms.values {
            for instrument in instruments.values {
                buffer.append(instrument.measure())
            }
        }
        return buffer
    }
}
