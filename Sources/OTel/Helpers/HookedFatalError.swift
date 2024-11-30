//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import class Foundation.Thread
import struct NIOConcurrencyHelpers.NIOLockedValueBox

func fatalError(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    print("hooking fatal error")
    hookedFatalError(message(), file: file, line: line)
}

package typealias FatalErrorHandler = @Sendable (String, _: StaticString, _: UInt) -> Void

private let fatalErrorHandler: NIOLockedValueBox<FatalErrorHandler?> = .init(nil)

private func hookedFatalError(_ message: String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    if let fatalErrorHandler = fatalErrorHandler.withLockedValue({ $0 }) {
        print("\(#function): Running custom handler")
        fatalErrorHandler(message, file, line)
        print("\(#function): Parking thread")
        while true { Thread.sleep(until: .distantFuture) }
    } else {
        Swift.fatalError(message, file: file, line: line)
    }
}

package func withHookedFatalError<T>(
    _ operation: () throws -> T,
    onFatalError: @escaping FatalErrorHandler
) rethrows -> T {
    let previousFatalErrorHandler = fatalErrorHandler.withLockedValue {
        let previousFatalErrorHandler = $0
        $0 = onFatalError
        return previousFatalErrorHandler
    }
    defer { fatalErrorHandler.withLockedValue { $0 = previousFatalErrorHandler } }
    return try operation()
}
