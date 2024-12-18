//
//  File.swift
//  SPMTest
//
//  Created by Gavin Xiang on 12/18/24.
//

import Performance
import MJRefresh

@MainActor
@objcMembers public class SPMTestManager: NSObject {
    public static let shared = SPMTestManager()
    
    public func testPerformance() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        print("\(#function)")
        Performance().startMonitor()
//        let model = OCModel()
//        print("\(model.age)")
    }
    
    public func testMJRefresh() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        print("\(#function)")
        let tableVc = UITableViewController()
        let action: MJRefreshComponentAction = {
            print("refresh")
        }
        DispatchQueue.main.async {
            tableVc.tableView.mj_header = MJRefreshHeader(refreshingBlock: action)
        }
    }
}
