//
//  System.swift
//  Performance
//
//  Created by michael.ledger on 2023/8/16.
//

import Foundation

public enum System {
    /// System uptime include sleep time
    public static var uptime: time_t {
        var boottime = timeval()
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        var size = MemoryLayout<timeval>.stride

        var now = time_t()
        var uptime: time_t = -1

        time(&now)
        if sysctl(&mib, 2, &boottime, &size, nil, 0) != -1, boottime.tv_sec != 0 {
            uptime = now - boottime.tv_sec
        }
        return uptime
    }

    /// System uptime without sleep time
    public static var systemUptime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}
