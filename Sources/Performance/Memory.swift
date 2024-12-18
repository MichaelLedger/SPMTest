//
//  Memory.swift
//  Performance
//
//  Created by michael.ledger on 2023/8/16.
//

import Foundation

public enum Memory {
    /// 获取设备已使用的内存
    static var memoryUsage: Double? {
        guard let memory = memoryFootprint() else { return nil }
        let memoryInMB = Double(memory) / (1024 * 1024)
        return round(memoryInMB * 10) / 10
    }

    /// https://developer.apple.com/forums/thread/105088?answerId=357415022#357415022
    private static func memoryFootprint() -> mach_vm_size_t? {
        // The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
        // complex for the Swift C importer, so we have to define them ourselves.
        let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
        var info = task_vm_info_data_t()
        var count = TASK_VM_INFO_COUNT
        let kernelReturn = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard kernelReturn == KERN_SUCCESS, count >= TASK_VM_INFO_REV1_COUNT else { return nil }
        return info.phys_footprint
    }
}
