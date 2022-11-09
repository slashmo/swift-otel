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
    public enum NumericValue {
        case double(Double)
        case int(Int64)
    }
    
    public struct NumericDataPoint {
        public let unixTimeNanoseconds: UInt64
        public let attributes: [(String, String)]
        public let value: NumericValue
    }
    
    public struct HistogramDataPoint {
        public let unixTimeNanoseconds: UInt64
        public let value: NumericValue
    }
    
    public enum RecordedMetric {
        case sum(Sum)
        case gauge(Gauge)
        case histogram(Histogram)
        case exponentialHistogram(ExponentialHistogram)
        case summary(Summary)
        
        public var resource: OTel.Resource {
            switch self {
            case .sum(let metric):
                return metric.resource
            case .gauge(let metric):
                return metric.resource
            case .histogram(let metric):
                return metric.resource
            case .exponentialHistogram(let metric):
                return metric.resource
            case .summary(let metric):
                return metric.resource
            }
        }
        
        public var label: String {
            switch self {
            case .sum(let metric):
                return metric.label
            case .gauge(let metric):
                return metric.label
            case .histogram(let metric):
                return metric.label
            case .exponentialHistogram(let metric):
                return metric.label
            case .summary(let metric):
                return metric.label
            }
        }
    }
    
    public struct Sum {
        /// The resource on which this metric was recorded.
        public let resource: OTel.Resource
        
        public let label: String
        
        public let dimensions: [(String, String)]
        
        public let dataPoints: [NumericValue]
        
        public let isCumulative: Bool
        
        public let isMonotonic: Bool
    }
    
    public struct Gauge {
        /// The resource on which this metric was recorded.
        public let resource: OTel.Resource
        
        public let label: String
        
        public let dimensions: [(String, String)]
        
        public let dataPoints: [NumericValue]
    }
    
    public struct Histogram {
        /// The resource on which this metric was recorded.
        public let resource: OTel.Resource
        
        public let label: String
        
        public let dimensions: [(String, String)]
        
        public let dataPoints: [HistogramDataPoint]
    }
    
    public struct ExponentialHistogram {
        /// The resource on which this metric was recorded.
        public let resource: OTel.Resource
        
        public let label: String
        
        public let dimensions: [(String, String)]
        
        public let dataPoints: [HistogramDataPoint]
    }
    
    public struct Summary {
        /// The resource on which this metric was recorded.
        public let resource: OTel.Resource
        
        public let label: String
        
        public let dimensions: [(String, String)]
        
        // public let dataPoints: [HistogramDataPoint]
    }
}
