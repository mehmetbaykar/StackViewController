//
//  StackPanGestureRecognizer.swift
//  StackViewControllerDemo
//
//  Created by guojiubo on 8/28/15.
//  Copyright (c) 2015 CocoaWind. All rights reserved.
//

import UIKit

class StackPanGestureRecognizer: UIPanGestureRecognizer {
    
    enum StackPanGestureDirection {
        case Push, Pop
    }
    
    weak var scrollView: UIScrollView?
    
    private(set) var direction: StackPanGestureDirection?
    
    private var failed: Bool?
    
    override func reset() {
        super.reset()
        self.direction = nil
        self.failed = nil
    }
    

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        guard self.state != .failed else {
            return
        }
        
        if let failed = self.failed {
            if failed {
                self.state = .failed
            }
            return
        }
        
        guard let touch = touches.first else {
            return
        }
        
        let currentLocation = touch.location(in: self.view)
        let previousLocation = touch.previousLocation(in: self.view)
        
        let translation = CGPoint(x: currentLocation.x - previousLocation.x, y: currentLocation.y - previousLocation.y)
        
        if abs(translation.y) > abs(translation.x) {
            self.state = .failed
            self.failed = true
            return
        } else {
            self.failed = false
        }
        
        if (currentLocation.x > previousLocation.x) {
            self.direction = .Pop
        }
        else if (currentLocation.x < previousLocation.x) {
            self.direction = .Push
        }
        else {
            self.direction = nil
        }
        
        
        // deal with scroll view
        
        guard let scrollView = self.scrollView else {
            return
        }
        
        if self.direction == .Pop {
            let fixedOffsetX = scrollView.contentOffset.x + scrollView.contentInset.left
            if fixedOffsetX <= 0 {
                self.failed = false
            } else {
                self.state = .failed
                self.failed = true
            }
            return
        }
        
        if self.direction == .Push {
            let fixedOffsetX = scrollView.contentOffset.x - scrollView.contentInset.right
            if fixedOffsetX + scrollView.bounds.size.width >= scrollView.contentSize.width {
                self.failed = false
            } else {
                self.state = .failed
                self.failed = true
            }
        }
    }
   
}
