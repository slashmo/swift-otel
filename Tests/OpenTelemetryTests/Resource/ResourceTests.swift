import OpenTelemetry
import XCTest

final class ResourceTests: XCTestCase {
    func test_mergingTwoResources() {
        let resourceA = OTel.Resource(attributes: ["a": "test"])
        let resourceB = OTel.Resource(attributes: ["b": "test"])

        let resourceC = resourceA.merging(resourceB)

        XCTAssertEqual(resourceC.attributes.count, 2, "Merged resource should contain both attributes.")
    }
}
