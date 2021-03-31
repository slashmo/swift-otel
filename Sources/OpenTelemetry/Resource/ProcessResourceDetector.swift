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

import class Foundation.ProcessInfo
import NIO
import Tracing

extension OTel {
    struct ProcessResourceDetector: OTelResourceDetector {
        private let eventLoopGroup: EventLoopGroup

        init(eventLoopGroup: EventLoopGroup) {
            self.eventLoopGroup = eventLoopGroup
        }

        func detect() -> EventLoopFuture<Resource> {
            var attributes: SpanAttributes = [:]
            attributes["process.pid"] = Int(ProcessInfo.processInfo.processIdentifier)
            attributes["process.executable.name"] = ProcessInfo.processInfo.processName
            attributes["process.executable.path"] = CommandLine.arguments[0]
            attributes["process.command"] = CommandLine.argc > 1 ? CommandLine.arguments[1] : nil
            attributes["process.command_line"] = CommandLine.arguments.joined(separator: " ")
            #if os(macOS)
            if #available(macOS 10.12, *) {
                attributes["process.owner"] = ProcessInfo.processInfo.userName
            }
            #else
            attributes["process.owner"] = ProcessInfo.processInfo.userName
            #endif

            return eventLoopGroup.next().makeSucceededFuture(Resource(attributes: attributes))
        }
    }
}
