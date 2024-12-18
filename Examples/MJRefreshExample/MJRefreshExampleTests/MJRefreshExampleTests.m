//
//  MJRefreshExampleTests.m
//  MJRefreshExampleTests
//
//  Created by MJ Lee on 15/3/4.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
@import MJRefresh;

@interface MJRefreshExampleTests : XCTestCase

@end

@implementation MJRefreshExampleTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    NSLog(@"%s", __FUNCTION__);
    // This is an example of a functional test case.
    UITableViewController *tableVc = [[UITableViewController alloc] init];
    // 设置回调（一旦进入刷新状态就会调用这个refreshingBlock）
    tableVc.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        NSLog(@"==beginRefreshing==");
    }];
    // 马上进入刷新状态
    [tableVc.tableView.mj_header beginRefreshing];
    XCTAssert(YES, @"MJRefresh Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
