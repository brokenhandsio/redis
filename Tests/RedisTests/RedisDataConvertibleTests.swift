import Foundation
@testable import Redis
import XCTest

class RedisDataConvertibleTests: XCTestCase {
    func testArrayToRedisData() throws {
        let data = try [
            RedisData(integerLiteral: 3),
            RedisData(integerLiteral: 1),
            RedisData(stringLiteral: "Some string")
        ].convertToRedisData()

        XCTAssertNotNil(data.array)
        XCTAssertEqual(data.array?[0].int, 3)
        XCTAssertEqual(data.array?[1].int, 1)
        XCTAssertEqual(data.array?[2].string, "Some string")
    }

    func testArrayFromData() throws {
        var data = RedisData(arrayLiteral: .integer(3), .integer(1))
        let results: [Int] = try .convertFromRedisData(data)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0], 3)
        XCTAssertEqual(results[1], 1)

        data = RedisData(arrayLiteral: .integer(2), .bulkString("Vapor"), .null)
        XCTAssertThrowsError(try Array<Int>.convertFromRedisData(data))
    }

    static let allTests = [
        ("testArrayToRedisData", testArrayToRedisData),
        ("testArrayFromData", testArrayFromData),
    ]
}
