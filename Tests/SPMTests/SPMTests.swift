//
//  PerformanceTests.swift
//  SPMTest
//
//  Created by Gavin Xiang on 12/17/24.
//

import Testing
import XCTest
import SPMLib
import Performance
import MJRefresh
import RxSwift
import RxCocoa
import RxRelay
import RxGesture

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
        
        Performance().startMonitor()

        let tableVc = await UITableViewController()
        let action: MJRefreshComponentAction = {
            print("refresh")
        }
        await tableVc.tableView.mj_header = await MJRefreshHeader(refreshingBlock: action)
        
        let btn = UIButton(type: .custom)
        btn.rx.controlEvent(.touchUpInside).throttle(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: {
            print("tap")
        }).disposed(by: DisposeBag())
        
        UIView().rx.tapGesture().when(.recognized).subscribe(onNext: { _ in 
            print("tap")
        }).disposed(by: DisposeBag())
        
        XCTAssert(true, "Pass");
    }

}
