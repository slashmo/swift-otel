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

import struct Dispatch.DispatchWallTime
import Tracing

extension OTel {
    public struct NumericDataPoint {
        public enum Value {
            case double(Double)
            case int(Int64)
        }
        
        public let unixTimeNanoseconds: UInt64
        public let attributes: [(String, String)]
        public let value: Value
    }
    
    public enum MetricValue {
//        case sum()
    }
    
    public struct RecordedMetric {
        /// The resource on which this metric was recorded.
        public let resource: OTel.Resource
        
        public let label: String
         
    }
}
//
//extension OTel.RecordedSpan {
//    init?(_ span: OTel.Tracer.Span) {
//        guard let context = span.baggage.spanContext else { return nil }
//        guard let endTime = span.endTime else { return nil }
//
//        self.operationName = span.operationName
//        self.kind = span.kind
//        self.status = span.status
//        self.context = context
//
//        // strip span context from baggage because it's already stored as `context`.
//        var baggage = span.baggage
//        baggage.spanContext = nil
//        self.baggage = baggage
//
//        self.startTime = span.startTime
//        self.endTime = endTime
//
//        self.attributes = span.attributes
//        self.events = span.events
//        self.links = span.links
//        self.resource = span.resource
//    }
//}
