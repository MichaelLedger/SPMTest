//
//  Wakeup.swift
//  Performance
//
//  Created by michael.ledger on 2023/8/30.
//

import Foundation

public enum Wakeups {
    static var interruptWakeups: UInt64? {
        let TASK_POWER_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_power_info_data_t>.size / MemoryLayout<integer_t>.size)
        var info = task_power_info_data_t()
        var count = TASK_POWER_INFO_COUNT
        let kernelReturn = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_POWER_INFO), $0, &count)
            }
        }
        guard kernelReturn == KERN_SUCCESS else { return nil }
        return info.task_interrupt_wakeups
    }
}
