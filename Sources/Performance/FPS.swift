//
//  FPS.swift
//  Performance
//
//  Created by michael.ledger on 2023/8/30.
//

import Foundation

#if os(iOS) || os(tvOS)

import QuartzCore

public class FPS {
    private var displayLink: CADisplayLink?
    private var lastTime: TimeInterval = 0
    private var count: UInt = 0
    private var _fps: UInt?

    public var fps: UInt? {
        if displayLink == nil || displayLink?.isPaused == true {
            configureDisplayLink()
            return nil
        }
        return _fps
    }

    private func configureDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkAction(link:)))
        displayLink?.isPaused = false
        displayLink?.add(to: .main, forMode: .common)
    }
    
    public func pause() {
        displayLink?.isPaused = true
        displayLink?.remove(from: .main, forMode: .common)
        lastTime = 0
        count = 0
        _fps = 0
    }
    
    public func resume() {
        displayLink?.isPaused = false
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func displayLinkAction(link: CADisplayLink) {
        guard lastTime != 0 else {
            lastTime = link.timestamp
            return
        }
        count += 1
        let delta = link.timestamp - lastTime
        guard delta >= 1 else { return }
        lastTime = link.timestamp
        let fps = Double(count) / delta
        count = 0
        _fps = UInt(round(fps))
    }
}

#endif
