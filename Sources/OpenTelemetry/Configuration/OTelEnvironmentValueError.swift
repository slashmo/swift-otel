//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2023 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An error indicating that the value for a given key in an ``OTelEnvironment`` is malformed.
public struct OTelEnvironmentValueError: Error, Equatable {
    /// The environment key.
    public let key: String

    /// The malformed environment value.
    public let value: String
    
    /// Create an ``OTelEnvironmentValueError`` with the given key and malformed value.
    ///
    /// - Parameters:
    ///   - key: The environment key.
    ///   - value: The malformed environment value.
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
