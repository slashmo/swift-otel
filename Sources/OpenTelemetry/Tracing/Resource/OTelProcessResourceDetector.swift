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

import Foundation
import Tracing

@_spi(Testing)
public struct OTelProcessResourceDetector: OTelResourceDetector {
    public let description = "process"

    private let processIdentifier: @Sendable () -> Int32
    private let executableName: @Sendable () -> String
    private let executablePath: @Sendable () -> String
    private let command: @Sendable () -> String?
    private let commandLine: @Sendable () -> String
    private let owner: @Sendable () -> String?

    public init(
        processIdentifier: @escaping @Sendable () -> Int32 = { ProcessInfo.processInfo.processIdentifier },
        executableName: @escaping @Sendable () -> String = { ProcessInfo.processInfo.processName },
        executablePath: @escaping @Sendable () -> String = { ProcessInfo.processInfo.arguments[0] },
        command: @escaping @Sendable () -> String? = {
            ProcessInfo.processInfo.arguments.count > 1 ? ProcessInfo.processInfo.arguments[1] : nil
        },
        commandLine: @escaping @Sendable () -> String = { ProcessInfo.processInfo.arguments.joined(separator: " ") },
        owner: @escaping @Sendable () -> String? = {
            #if os(macOS) || os(Linux)
                return ProcessInfo.processInfo.userName
            #else
                return nil
            #endif
        }
    ) {
        self.processIdentifier = processIdentifier
        self.executableName = executableName
        self.executablePath = executablePath
        self.command = command
        self.commandLine = commandLine
        self.owner = owner
    }

    public func resource() async -> OTelResource {
        var attributes: SpanAttributes = [:]

        attributes["process.pid"] = SpanAttribute.int32(processIdentifier())
        attributes["process.executable.name"] = "\(executableName())"
        attributes["process.executable.path"] = "\(executablePath())"
        attributes["process.command"] = command().map { "\($0)" }
        attributes["process.command_line"] = "\(commandLine())"
        attributes["process.owner"] = owner().map { "\($0)" }

        return OTelResource(attributes: attributes)
    }
}
