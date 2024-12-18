//
//  CPU.swift
//  Performance
//
//  Created by michael.ledger on 2023/8/16.
//

import Foundation

public enum CPU {
    /// 获取设备 CPU 的占用率
    static var cpuUsage: Double? {
        var totalUsageOfCPU: Double?
        var threadsList: thread_act_array_t?
        var threadsCount: mach_msg_type_number_t = 0
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)
        if let threadsList = threadsList, threadsResult == KERN_SUCCESS {
            for index in 0 ..< threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                guard infoResult == KERN_SUCCESS else {
                    break
                }
                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU = ((totalUsageOfCPU ?? 0) + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0))
                }
            }
        }
        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        return totalUsageOfCPU
    }
}
