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

    /// Retrieve a configuration value by transforming an appropriate senvironment value into the given type.
    ///
    /// ## Value Precedence
    ///
    /// When retrieving a configuration value the following precedence applies:
    /// 1. `programmaticOverride`, unless it's `nil`
    /// 2. `signalSpecificKey`, if a value is present
    /// 3. `sharedKey`, if a value is present
    ///
    /// - Parameters:
    ///   - programmaticOverride: A value override directly from code, taking precendence over all other values.
    ///   - signalSpecificKey: The environment key for the signal-specific configuration value.
    ///   - sharedKey: The environment key for the configuration value shared amongst all signals.
    ///   - transformValue: A closure transforming environment values into the given type.
    ///
    /// - Returns: The configuration value with the highest specificity, or `nil` if no configuration value was found.
    /// - Throws: ``OTelEnvironmentValueError`` is an environment value could not be transformed into the given type.
    public func value<T>(
        programmaticOverride: T?,
        signalSpecificKey: String,
        sharedKey: String,
        transformValue: @escaping (_ value: String) -> T?
    ) throws -> T? {
        if let programmaticOverride {
            return programmaticOverride
        }

        if let value = values[signalSpecificKey] {
            return try transformedValue(value, forKey: signalSpecificKey, using: transformValue)
        } else if let value = values[sharedKey] {
            return try transformedValue(value, forKey: sharedKey, using: transformValue)
        }

        return nil
    }
    
    /// Retrieve a boolean by transforming an appropriate environment value.
    ///
    /// - Parameters:
    ///   - programmaticOverride: A value override directly from code, taking precendence over all other values.
    ///   - signalSpecificKey: The environment key for the signal-specific configuration value.
    ///   - sharedKey: The environment key for the configuration value shared amongst all signals.
    ///
    /// - Returns: The configuration value with the highest specificity, or `nil` if no configuration value was found.
    /// - Throws: ``OTelEnvironmentValueError`` is an environment value could not be transformed into the given type.
    public func value(
        programmaticOverride: Bool?,
        signalSpecificKey: String,
        sharedKey: String
    ) throws -> Bool? {
        try value(
            programmaticOverride: programmaticOverride,
            signalSpecificKey: signalSpecificKey,
            sharedKey: sharedKey,
            transformValue: { value in
                if value.lowercased() == "true" {
                    return true
                } else if value.lowercased() == "false" {
                    return false
                } else {
                    return nil
                }
            }
        )
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

    /// Extract headers from a given environment value.
    ///
    /// - Parameter value: The value containing a comma-separated list of headers.
    /// - Returns: The extracted headers as an array of key-value pairs, or nil if parsing fails.
    public static func headers(parsingValue value: String) -> [(key: String, value: String)]? {
        var headers = [(key: String, value: String)]()

        let keyValuePairs = value.split(separator: ",")
        for keyValuePair in keyValuePairs {
            guard let valueSeparatorIndex = keyValuePair.firstIndex(of: "=") else {
                return nil
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

    private func transformedValue<T>(
        _ value: String,
        forKey key: String,
        using transform: (String) -> T?
    ) throws -> T {
        guard let value = transform(value) else {
            throw OTelEnvironmentValueError(key: key, value: value)
        }
        return value
    }
}

extension OTelEnvironment: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.values = [String: String](uniqueKeysWithValues: elements)
    }
}
