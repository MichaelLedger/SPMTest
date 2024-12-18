//
//  PerformanceTests.swift
//  SPMTest
//
//  Created by Gavin Xiang on 12/17/24.
//

import Testing
import XCTest
import SPMTest
import UIKit
//import Performance
//import MJRefresh

@MainActor
struct Test {

    @Test func testPerformance() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        print("\(#function)")
        let shared = SPMTestManager.shared
        do {
            try await shared.testPerformance()
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
        do {
            try await shared.testMJRefresh()
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
        
//        Performance().startMonitor()
        
////        let model = OCModel()
////        print("\(model.age)")
        ///
//        let tableVc = await UITableViewController()
//        let action: MJRefreshComponentAction = {
//            print("refresh")
//        }
//        await tableVc.tableView.mj_header = await MJRefreshHeader(refreshingBlock: action)
        
        XCTAssert(true, "Pass");
    }

}
