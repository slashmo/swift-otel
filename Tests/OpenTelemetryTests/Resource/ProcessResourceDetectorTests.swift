import NIO
@testable import OpenTelemetry
import XCTest

final class ProcessResourceDetectorTests: XCTestCase {
    func test_detectsProcessInfo() throws {
        let detector = OTel.ProcessResourceDetector(eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: 1))

        let resource = try detector.detect().wait()

        XCTAssertNotNil(resource.attributes["process.pid"])
        XCTAssertEqual(resource.attributes["process.executable.name"]?.toSpanAttribute(), "xctest")
        XCTAssertNotNil(resource.attributes["process.executable.path"])
        XCTAssertNotNil(resource.attributes["process.command"])
        XCTAssertNotNil(resource.attributes["process.command_line"])

        #if os(macOS)
        if #available(macOS 10.12, *) {
            XCTAssertNotNil(resource.attributes["process.owner"])
        }
        #else
        XCTAssertNotNil(resource.attributes["process.owner"])
        #endif
    }
}
