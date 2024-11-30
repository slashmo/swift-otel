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

@testable import OTel
@testable import OTelTesting
import XCTest

final class HookedFatalErrorTests: XCTestCase {
    func testHookedFatalError_functionFatalErrors_runsHandler() async {
        let functionReturned = expectation(description: "function returned")
        functionReturned.isInverted = true
        let fatalErrorHandlerRun = expectation(description: "handler run")
        DispatchQueue.global().async {
            withHookedFatalError {
                if true { fatalError("boom") }
            } onFatalError: { message, _, _ in
                XCTAssertEqual(message, "boom")
                fatalErrorHandlerRun.fulfill()
            }
            functionReturned.fulfill()
        }
        await fulfillment(of: [functionReturned, fatalErrorHandlerRun], timeout: 0.1)
    }

    func testHookedFatalError_functionDoesNotFatalError_doesNotrunHandler() async {
        let functionReturned = expectation(description: "function returned")
        let fatalErrorHandlerRun = expectation(description: "handler run")
        fatalErrorHandlerRun.isInverted = true
        DispatchQueue.global().async {
            withHookedFatalError {} onFatalError: { _, _, _ in
                fatalErrorHandlerRun.fulfill()
            }
            functionReturned.fulfill()
        }
        await fulfillment(of: [functionReturned, fatalErrorHandlerRun], timeout: 0.1)
    }

    func testXCTAssertThrowsFatalError() async {
        XCTAssertThrowsFatalError {
            fatalError()
        }
        XCTAssertThrowsFatalError("foo") {
            fatalError("foo")
        }
    }
}
