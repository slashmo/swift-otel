import Tracing
import W3CTraceContext

/// An `OTelSampler` based on a given `TraceID` and `ratio`.
/// [Spec](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/sdk.md#traceidratiobased)
public struct OTelTraceIdRatioBasedSampler: OTelSampler, Equatable, Hashable, CustomStringConvertible {

    let idUpperBound : UInt64
    public let ratio: Double

    public init(ratio: Double) {
        precondition(ratio >= 0.0 && ratio <= 1.0, "ratio must be between 0.0 and 1.0")

        self.ratio = ratio
        if ratio == 0.0 {
            self.idUpperBound = .min
        } else if ratio == 1.0 {
            self.idUpperBound = .max
        } else {
            self.idUpperBound = UInt64(ratio * Double(UInt64.max))
        }
    }

    public func samplingResult(
        operationName: String,
        kind: SpanKind,
        traceID: TraceID,
        attributes: SpanAttributes,
        links: [SpanLink],
        parentContext: ServiceContext
    ) -> OTelSamplingResult {

        let value = traceID.withUnsafeBytes { $0[8...].load(as: UInt64.self) }

        if value < idUpperBound {
            return .init(decision: .recordAndSample)
        } else {
            return .init(decision: .drop)
        }
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.idUpperBound == rhs.idUpperBound
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.idUpperBound)
    }

    public var description: String {
        "TraceIdRatioBased{\(ratio)}"
    }
}