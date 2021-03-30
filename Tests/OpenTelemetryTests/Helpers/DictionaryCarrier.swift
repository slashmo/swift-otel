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

import Instrumentation

public struct DictionaryInjector: Injector {
    public init() {}

    public func inject(_ value: String, forKey key: String, into carrier: inout [String: String]) {
        carrier[key] = value
    }
}

public struct DictionaryExtractor: Extractor {
    public init() {}

    public func extract(key: String, from carrier: [String: String]) -> String? {
        carrier[key]
    }
}
