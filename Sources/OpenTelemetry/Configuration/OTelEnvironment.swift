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

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import Foundation

/// A wrapper for reading environment values.
public struct OTelEnvironment {
    /// The key-value pairs in the environment.
    public let values: [String: String]

    /// Create an environment wrapping the given key-value pairs.
    ///
    /// - Parameter values: The key-value pairs to wrap.
    public init(values: [String : String]) {
        self.values = values
    }

    /// Extract headers from a given environment key.
    ///
    /// - Parameter key: The key for which to extract headers.
    /// - Returns: The extracted headers as an array of key-value pairs, or nil if no value exists for the given key.
    public func headers(fromValueForKey key: String) throws -> [(key: String, value: String)]? {
        guard let value = values[key] else { return nil }

        var headers = [(key: String, value: String)]()

        let keyValuePairs = value.split(separator: ",")
        for keyValuePair in keyValuePairs {
            guard let valueSeparatorIndex = keyValuePair.firstIndex(of: "=") else {
                throw OTelEnvironmentValueError(key: key, value: value)
            }
            let key = keyValuePair
                .prefix(upTo: valueSeparatorIndex)
                .trimmingCharacters(in: .whitespaces)
            let value = keyValuePair[keyValuePair.index(after: valueSeparatorIndex)...]
                .trimmingCharacters(in: .whitespaces)
            headers.append((key, value))
        }

        return headers
    }
    
    /// An ``OTelEnvironment`` exposing the process-wide environment values.
    ///
    /// - Returns: An ``OTelEnvironment`` exposing the process-wide environment values.
    public static func detected() -> OTelEnvironment {
        var values = [String: String]()

        let environmentPointer = environ
        var index = 0

        while let entry = environmentPointer.advanced(by: index).pointee {
            let entry = String(cString: entry)
            if let i = entry.firstIndex(of: "=") {
                let key = entry.prefix(upTo: i).uppercased()
                let value = String(entry[i...].dropFirst("=".count))
                values[key] = value
            }
            index += 1
        }

        return OTelEnvironment(values: values)
    }
}

extension OTelEnvironment: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.values = [String: String](uniqueKeysWithValues: elements)
    }
}
