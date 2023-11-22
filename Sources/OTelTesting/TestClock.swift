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

import NIOConcurrencyHelpers

public final class TestClock: Clock, @unchecked Sendable {
    public struct Instant: InstantProtocol {
        public var offset: Duration

        public init(offset: Duration = .zero) {
            self.offset = offset
        }

        public func advanced(by duration: Duration) -> Self {
            .init(offset: offset + duration)
        }

        public func duration(to other: Self) -> Duration {
            other.offset - offset
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    public var minimumResolution: Duration = .zero
    public var now: Instant {
        state.withLockedValue { $0.now }
    }

    struct State {
        // We should use a Heap here
        var continuations: [(id: UInt64, deadline: Instant, continuation: CheckedContinuation<Void, Error>)]
        var now: Instant
    }

    public let sleepCalls: AsyncStream<Void>
    private let sleepCallsContinuation: AsyncStream<Void>.Continuation

    private let state = NIOLockedValueBox(State(continuations: [], now: .init()))

    public init(now: Instant = .init()) {
        state.withLockedValue { $0.now = now }
        let (stream, continunation) = AsyncStream<Void>.makeStream()
        sleepCalls = stream
        sleepCallsContinuation = continunation
    }

    public func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.state.withLockedValue { state in
                    if deadline <= state.now {
                        continuation.resume()
                    }

                    let id = UInt64.random(in: .min ..< .max)
                    state.continuations.append((id, deadline, continuation))
                }
                sleepCallsContinuation.yield()
            }
        } onCancel: {
            self.state.withLockedValue { state in
                for entry in state.continuations {
                    entry.continuation.resume(throwing: CancellationError())
                    state.continuations.removeAll(where: { $0.id == entry.id })
                }
            }
        }
    }

    public func advance(by duration: Duration = .zero) {
        state.withLockedValue { state in
            let newDeadline = state.now.advanced(by: duration)
            precondition(state.now < newDeadline)
            state.now = newDeadline

            state.continuations.lazy.filter { $0.deadline <= newDeadline }.forEach { $0.continuation.resume() }
            state.continuations.removeAll { $0.deadline <= newDeadline }
        }
    }

    public func advance(to deadline: Instant) {
        state.withLockedValue { state in
            precondition(state.now < deadline)
            state.now = deadline

            state.continuations.lazy.filter { $0.deadline <= deadline }.forEach { $0.continuation.resume() }
            state.continuations.removeAll { $0.deadline <= deadline }
        }
    }
}
