//
//  Performance.swift
//  Performance
//
//  Created by michael.ledger on 2023/6/19.
//

import Foundation
import QuartzCore
import OSLog

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.5)
#error("Performance doesn't support Swift versions below 5.5.")
#endif

/// Current Performance version. Necessary since SPM doesn't use dynamic libraries. Plus this will be more accurate.
let version = "1.0.2"

@objcMembers public class Performance: NSObject {
    
    public let _fps = FPS()
    
    public var preferredFramesPerSecond: Int = 1
    
    private var displayLink: CADisplayLink?
    
    public func startMonitor() {
        performMainLogger()
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkAction(link:)))
        displayLink?.isPaused = false
        displayLink?.preferredFramesPerSecond = preferredFramesPerSecond
        displayLink?.add(to: .main, forMode: .common)
    }
    
    public func pauseMonitor() {
        displayLink?.isPaused = true
        displayLink?.remove(from: .main, forMode: .common)
    }
    
    public func resumeMonitor() {
        performMainLogger()
        
        displayLink?.isPaused = false
        displayLink?.add(to: .main, forMode: .common)
    }
    
    public func performMainLogger() {
        Logger.performance.info("System uptime include sleep time: \(self.uptime) seconds")
        Logger.performance.info("System uptime without sleep time: \(self.systemUptime) seconds")
        if let interruptWakeups = interruptWakeups {
            Logger.performance.info("Interrupt Wakeups: \(interruptWakeups)")
        }
    }
    
    public func performTimerLogger() {
        if let fps = fps {
            Logger.performance.info("FPS: \(fps)")
        }
        if let cpuUsage = cpuUsage {
            Logger.performance.info("CPU Usage:\(cpuUsage)%")
        }
        if let memoryUsage = memoryUsage {
            Logger.performance.info("Memory Usage: \(memoryUsage) MB")
        }
    }
    
    @objc private func displayLinkAction(link: CADisplayLink) {
        performTimerLogger()
    }
    
}

// MARK: - Memory

public extension Performance {
    var memoryUsage: Double? { Memory.memoryUsage }
}

// MARK: - CPU

public extension Performance {
    var cpuUsage: Double? { CPU.cpuUsage }
}

// MARK: - Wakeups

public extension Performance {
    var interruptWakeups: UInt64? { Wakeups.interruptWakeups }
}

// MARK: - FPS

public extension Performance {
    var fps: UInt? { _fps.fps }
}

// MARK: - System uptime include sleep time

public extension Performance {
    var uptime: time_t { System.uptime }
}

// MARK: - System uptime without sleep time

public extension Performance {
    var systemUptime: TimeInterval { System.systemUptime }
}
