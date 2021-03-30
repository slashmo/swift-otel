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

import struct Dispatch.DispatchWallTime
import NIOConcurrencyHelpers
import Tracing

extension OTel {
    final class Tracer {
        private let resource: OTel.Resource
        private var idGenerator: IDGenerator
        private let sampler: Sampler
        private let processor: SpanProcessor
        private let logger: Logger

        init(
            resource: OTel.Resource,
            idGenerator: IDGenerator,
            sampler: Sampler,
            processor: SpanProcessor,
            logger: Logger
        ) {
            self.resource = resource
            self.idGenerator = idGenerator
            self.sampler = sampler
            self.processor = processor
            self.logger = logger
        }
    }
}

extension OTel.Tracer: Instrument {
    func extract<Carrier, Extract>(
        _ carrier: Carrier,
        into baggage: inout Baggage,
        using extractor: Extract
    ) where Carrier == Extract.Carrier, Extract: Extractor {}

    func inject<Carrier, Inject>(
        _ baggage: Baggage,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Injector {}
}

extension OTel.Tracer: Tracer {
    func startSpan(
        _ operationName: String,
        baggage: Baggage,
        ofKind kind: SpanKind,
        at time: DispatchWallTime
    ) -> Tracing.Span {
        let parentBaggage = baggage
        var childBaggage = baggage

        let traceID: OTel.TraceID
        let traceState: OTel.TraceState
        let spanID = idGenerator.generateSpanID()

        if let parentSpanContext = parentBaggage.spanContext {
            traceID = parentSpanContext.traceID
            traceState = parentSpanContext.traceState
        } else {
            traceID = idGenerator.generateTraceID()
            traceState = OTel.TraceState([])
        }

        let samplingResult = sampler.makeSamplingDecision(
            operationName: operationName,
            kind: kind,
            traceID: traceID,
            attributes: [:],
            links: [],
            parentBaggage: parentBaggage
        )
        let traceFlags: OTel.TraceFlags = samplingResult.decision == .recordAndSample ? .sampled : []
        let spanContext = OTel.SpanContext(
            traceID: traceID,
            spanID: spanID,
            parentSpanID: parentBaggage.spanContext?.spanID,
            traceFlags: traceFlags,
            traceState: traceState,
            isRemote: false
        )
        childBaggage.spanContext = spanContext

        if samplingResult.decision == .drop {
            return NoOpTracer.NoOpSpan(baggage: childBaggage)
        }

        return Span(
            operationName: operationName,
            baggage: childBaggage,
            kind: kind,
            startTime: time,
            attributes: samplingResult.attributes,
            logger: logger
        ) { [weak self] recordedSpan in
            guard let self = self else { return }
            self.processor.processEndedSpan(recordedSpan, on: self.resource)
        }
    }

    func forceFlush() {}
}

extension OTel.Tracer {
    final class Span: Tracing.Span {
        let operationName: String
        let kind: SpanKind
        private(set) var status: SpanStatus?

        let baggage: Baggage

        let isRecording = true

        let startTime: DispatchWallTime
        private(set) var endTime: DispatchWallTime?

        var attributes: SpanAttributes = [:]
        private(set) var events = [SpanEvent]()
        private(set) var links = [SpanLink]()

        private let logger: Logger
        private let lock = Lock()

        private let onEnd: (OTel.RecordedSpan) -> Void

        init(
            operationName: String,
            baggage: Baggage,
            kind: SpanKind,
            startTime: DispatchWallTime,
            attributes: SpanAttributes,
            logger: Logger,
            onEnd: @escaping (OTel.RecordedSpan) -> Void
        ) {
            self.operationName = operationName
            self.baggage = baggage
            self.kind = kind
            self.startTime = startTime
            self.attributes = attributes
            self.logger = logger
            self.onEnd = onEnd
        }

        func setStatus(_ status: SpanStatus) {
            lock.withLockVoid {
                self.status = status
            }
        }

        func addEvent(_ event: SpanEvent) {
            lock.withLockVoid {
                events.append(event)
            }
        }

        func recordError(_ error: Error) {
            let event = SpanEvent(name: "exception", attributes: [
                "exception.type": .string(String(describing: type(of: error))),
                "exception.message": .string(String(describing: error)),
            ])
            addEvent(event)
        }

        func addLink(_ link: SpanLink) {
            lock.withLockVoid {
                links.append(link)
            }
        }

        func end(at time: DispatchWallTime) {
            lock.withLockVoid {
                if let endTime = endTime {
                    logger.debug("Ending a span which was ended before", metadata: [
                        "previous_end_time": .stringConvertible(endTime.rawValue),
                    ])
                    return
                }
                endTime = time
                guard let recordedSpan = OTel.RecordedSpan(self) else { return }
                onEnd(recordedSpan)
            }
        }
    }
}
