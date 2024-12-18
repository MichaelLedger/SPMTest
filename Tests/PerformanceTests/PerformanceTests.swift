//
//  PerformanceTests.swift
//  SPMTest
//
//  Created by Gavin Xiang on 12/17/24.
//

import Testing
import Performance
import XCTest

struct Test {

    @Test func testPerformance() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        print("\(#function)")
        Performance().startMonitor()
        XCTAssert(true, "Pass");
    }

}
