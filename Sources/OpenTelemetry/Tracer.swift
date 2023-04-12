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

import Logging
import NIOConcurrencyHelpers
import Tracing

extension OTel {
    public final class Tracer {
        private let resource: OTel.Resource
        private var idGenerator: OTelIDGenerator
        private let sampler: OTelSampler
        private let processor: OTelSpanProcessor
        private let propagator: OTelPropagator
        private let logger: Logger

        init(
            resource: OTel.Resource,
            idGenerator: OTelIDGenerator,
            sampler: OTelSampler,
            processor: OTelSpanProcessor,
            propagator: OTelPropagator,
            logger: Logger
        ) {
            self.resource = resource
            self.idGenerator = idGenerator
            self.sampler = sampler
            self.processor = processor
            self.propagator = propagator
            self.logger = logger
        }
    }
}

extension OTel.Tracer: Instrument {
    public func extract<Carrier, Extract>(
        _ carrier: Carrier,
        into baggage: inout Baggage,
        using extractor: Extract
    ) where Carrier == Extract.Carrier, Extract: Extractor {
        do {
            baggage.spanContext = try propagator.extractSpanContext(from: carrier, using: extractor)
        } catch {
            logger.debug("Failed to extract span context", metadata: [
                "carrier": .string(String(describing: carrier)),
                "error": .string(String(describing: error)),
            ])
        }
    }

    public func inject<Carrier, Inject>(
        _ baggage: Baggage,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Injector {
        guard let spanContext = baggage.spanContext else { return }
        propagator.inject(spanContext, into: &carrier, using: injector)
    }
}

extension OTel.Tracer: Tracer {
    public typealias TracerSpan = Span

    public func startAnySpan<Clock: TracerClock>(
        _ operationName: String,
        baggage: @autoclosure () -> Baggage,
        ofKind kind: SpanKind,
        clock: Clock,
        function: String,
        file fileID: String,
        line: UInt
    ) -> any Tracing.Span {
        startSpan(
            operationName,
            baggage: baggage(),
            ofKind: kind,
            clock: clock,
            function: function,
            file: fileID,
            line: line
        )
    }

    public func startSpan<Clock: TracerClock>(
        _ operationName: String,
        baggage: @autoclosure () -> Baggage,
        ofKind kind: SpanKind,
        clock: Clock,
        function: String,
        file fileID: String,
        line: UInt
    ) -> Span {
        let parentBaggage = baggage()
        var childBaggage = parentBaggage

        let traceID: OTel.TraceID
        let traceState: OTel.TraceState?
        let spanID = idGenerator.generateSpanID()

        if let parentSpanContext = parentBaggage.spanContext {
            traceID = parentSpanContext.traceID
            traceState = parentSpanContext.traceState
        } else {
            traceID = idGenerator.generateTraceID()
            traceState = nil
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
            return Span(
                operationName: operationName,
                baggage: childBaggage,
                kind: kind,
                startTime: clock.now.nanosecondsSinceEpoch,
                attributes: samplingResult.attributes,
                resource: resource,
                isRecording: false,
                logger: logger
            ) { [weak self] recordedSpan in
                self?.processor.processEndedSpan(recordedSpan)
            }
        }

        return Span(
            operationName: operationName,
            baggage: childBaggage,
            kind: kind,
            startTime: clock.now.nanosecondsSinceEpoch,
            attributes: samplingResult.attributes,
            resource: resource,
            logger: logger
        ) { [weak self] recordedSpan in
            self?.processor.processEndedSpan(recordedSpan)
        }
    }

    public func forceFlush() {}
}

extension OTel.Tracer {
    public final class Span: Tracing.Span {
        public var operationName: String {
            get {
                operationNameLock.withLock { _operationName }
            }
            set {
                operationNameLock.withLockVoid {
                    _operationName = newValue
                }
            }
        }
        private var _operationName: String
        private let operationNameLock = NIOLock()

        public let kind: SpanKind
        public private(set) var status: SpanStatus?

        public let baggage: Baggage

        public let isRecording: Bool

        public let startTime: UInt64
        private(set) var endTime: UInt64?

        public var attributes: SpanAttributes = [:]
        public private(set) var events = [SpanEvent]()
        public private(set) var links = [SpanLink]()
        let resource: OTel.Resource

        private let logger: Logger
        private let lock = NIOLock()

        private let onEnd: (OTel.RecordedSpan) -> Void

        init(
            operationName: String,
            baggage: Baggage,
            kind: SpanKind,
            startTime: UInt64,
            attributes: SpanAttributes,
            resource: OTel.Resource,
            isRecording: Bool = true,
            logger: Logger,
            onEnd: @escaping (OTel.RecordedSpan) -> Void
        ) {
            self._operationName = operationName
            self.baggage = baggage
            self.kind = kind
            self.startTime = startTime
            self.attributes = attributes
            self.resource = resource
            self.isRecording = isRecording
            self.logger = logger
            self.onEnd = onEnd
        }

        public func setStatus(_ status: SpanStatus) {
            lock.withLockVoid {
                self.status = status
            }
        }

        public func addEvent(_ event: SpanEvent) {
            lock.withLockVoid {
                events.append(event)
            }
        }

        public func recordError(_ error: Error, attributes: SpanAttributes) {
            let event = SpanEvent(name: "exception", attributes: [
                "exception.type": .string(String(describing: type(of: error))),
                "exception.message": .string(String(describing: error)),
            ])
            addEvent(event)
        }

        public func addLink(_ link: SpanLink) {
            lock.withLockVoid {
                links.append(link)
            }
        }

        public func end<Clock>(clock: Clock) where Clock: TracerClock {
            lock.withLockVoid {
                if let endTime = self.endTime {
                    if let spanContext = baggage.spanContext {
                        logger.trace("Ignoring a span that was ended before", metadata: [
                            "previousEndTime": .stringConvertible(endTime),
                            "traceID": .stringConvertible(spanContext.traceID),
                            "spanID": .stringConvertible(spanContext.spanID),
                        ])
                    } else {
                        logger.trace("Ignoring a span that was ended before", metadata: [
                            "previousEndTime": .stringConvertible(endTime),
                        ])
                    }
                    return
                }
                endTime = clock.now.nanosecondsSinceEpoch
                guard let recordedSpan = OTel.RecordedSpan(self) else { return }
                onEnd(recordedSpan)
            }
        }
    }
}
