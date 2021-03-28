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

extension OTel {
    /// A resource represents the entity being traced.
    /// The attributes of a resource are expressed using `SpanAttributes`.
    /// Resources are immutable, but multiple resources may be merged using `merge()`.
    /// - SeeAlso: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/resource/sdk.md#resource-sdk
    public struct Resource {
        /// The attributes describing this resource.
        public let attributes: SpanAttributes

        /// Create a new `OTelResource` with the given attributes.
        /// - Parameter attributes: The resource attributes, defaults to none.
        public init(attributes: SpanAttributes = [:]) {
            self.attributes = attributes
        }

        /// Creates a new `OTelResource` by merging the attributes of the given resource
        /// into this resource's attributes, overwriting values of duplicate keys with those
        /// of the other attributes.
        /// - Parameter other: `OTelResource` to merge.
        /// - Returns: New `OTelResource` combining the attributes from both resources.
        /// - SeeAlso: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/resource/sdk.md#merge
        public func merging(_ other: Resource) -> Resource {
            var attributes = self.attributes
            attributes.merge(other.attributes)
            return Resource(attributes: attributes)
        }
    }
}
