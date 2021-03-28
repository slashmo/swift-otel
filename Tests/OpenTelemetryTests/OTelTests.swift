import NIO
@testable import OpenTelemetry
import XCTest

final class OTelTests: XCTestCase {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    func test_detectsResourceAttributes() {
        let otel = OTel(serviceName: #function, eventLoopGroup: eventLoopGroup)
        XCTAssertNoThrow(try otel.start().wait())

        let attributes = otel.resource.attributes
        XCTAssertNotNil(attributes["telemetry.sdk.name"])
        XCTAssertNotNil(attributes["telemetry.sdk.language"])
        XCTAssertNotNil(attributes["telemetry.sdk.version"])

        XCTAssertGreaterThan(attributes.count, 3, "Expected default resource detectors to detect additional attributes.")

        XCTAssertNoThrow(try otel.shutdown().wait())
    }
}

//final class OTelTests: XCTestCase {
//    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//
//    func test_start_usesDefaultResourceDetectors() throws {
//        let otel = OTel(serviceName: #function, eventLoopGroup: eventLoopGroup)
//        XCTAssertNoThrow(try otel.start().wait())
//
//        let attributes = otel.resource.attributes
//        XCTAssertNotNil(attributes["telemetry.sdk.name"])
//        XCTAssertNotNil(attributes["telemetry.sdk.language"])
//        XCTAssertNotNil(attributes["telemetry.sdk.version"])
//
//        XCTAssertGreaterThan(attributes.count, 3, "Expected default resource detectors to detect additional attributes.")
//
//        XCTAssertNoThrow(try otel.shutdown().wait())
//    }
//
//    func test_start_withoutResourceDetection_onlySetsTelemetrySDKAttributes() throws {
//        let otel = try OTel.start(on: eventLoopGroup, resourceDetection: .none).wait()
//
//        let attributes = otel.resource.attributes
//
//        XCTAssertTrue(attributes.isEmpty, "Expected no attributes, got: \(attributes)")
//
//        XCTAssertNoThrow(try otel.shutdown().wait())
//    }
//
//    func test_start_withManualResourceDetection_containsTelemetrySDKAttributes() throws {
//        let resource = OTel.Resource(attributes: ["key": "value", "telemetry.sdk.version": "override"])
//        let otel = try OTel.start(on: eventLoopGroup, resourceDetection: .manual(resource)).wait()
//
//        let attributes = otel.resource.attributes
//
//        XCTAssertNotNil(attributes["telemetry.sdk.name"])
//        XCTAssertNotNil(attributes["telemetry.sdk.language"])
//        XCTAssertEqual(attributes["telemetry.sdk.version"]?.toSpanAttribute(), "override")
//        XCTAssertEqual(attributes["key"]?.toSpanAttribute(), "value")
//    }
//}
