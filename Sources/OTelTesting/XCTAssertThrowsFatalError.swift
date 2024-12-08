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

#if canImport(XCTest)
    import OTel
    import XCTest

    package func XCTAssertThrowsFatalError(
        _ expectedMessage: @escaping @Sendable @autoclosure () -> String? = nil,
        timeout seconds: TimeInterval = 0.1,
        _ expression: @escaping @Sendable () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let hookedFatalErrorCalled = XCTestExpectation(description: "hooked fatalError called")
        withHookedFatalError {
            DispatchQueue.global().async { expression() }
            guard case .completed = XCTWaiter.wait(for: [hookedFatalErrorCalled], timeout: seconds) else {
                XCTFail("Operation did not throw fatalError", file: file, line: line)
                return
            }
        } onFatalError: { message, _, _ in
            hookedFatalErrorCalled.fulfill()
            if let expectedMessage = expectedMessage() {
                XCTAssertEqual(message, expectedMessage, "Operation threw fatalError but with unexpected message", file: file, line: line)
            }
        }
    }
#endif
