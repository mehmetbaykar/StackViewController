//
//  StackViewControllerDemoTests.swift
//  StackViewControllerDemoTests
//
//  Created by guojiubo on 8/26/15.
//  Copyright (c) 2015 CocoaWind. All rights reserved.
//

import UIKit
import XCTest

//@testable
@testable import StackViewControllerDemo

class StackViewControllerDemoTests: XCTestCase {
    
    let a = UIViewController()
    let b = UIViewController()
    let c = UIViewController()
    let d = UIViewController()
    let e = UIViewController()
    let f = UIViewController()
    
    func testInitializations() {
        let stack1 = StackViewController()
        XCTAssertNotNil(stack1)
        XCTAssert(stack1.viewControllers.isEmpty)
        
        let root = UIViewController()
        let stack2 = StackViewController(rootViewController: root)
        XCTAssertNotNil(stack2)
        XCTAssert(stack2.viewControllers.count == 1)
        XCTAssert(stack2.viewControllers == [root])
        XCTAssert(stack2.rootViewController == root)
        
        XCTAssert(root.stackViewController == stack2)
    }
    
    func testPushViewController() {
        let stack = StackViewController()
        
        stack.pushViewController(toViewController: a, animated: false)
        XCTAssert(stack.topViewController! == a)
        
        stack.pushViewController(toViewController: b, animated: false)
        XCTAssert(stack.topViewController! == b)
        
        stack.pushViewController(toViewController: b, animated: false)
        XCTAssert(stack.topViewController! == b)
    }
    
    func testPopViewController() {
        let stack = StackViewController()
        stack.viewControllers = [a, b, c, d, e, f]
        
        var poppedViewController = stack.popViewControllerAnimated(animated: false)
        XCTAssert(stack.viewControllers == [a, b, c, d, e])
        XCTAssert(poppedViewController == f)
        
        var poppedViewControllers = stack.popToViewController(viewController: c, animated: false)
        XCTAssert(stack.viewControllers == [a, b, c])
        XCTAssert(poppedViewControllers == [d, e])
        
        poppedViewControllers = stack.popToRootViewControllerAnimated(animated: false)
        XCTAssert(stack.viewControllers == [a])
        XCTAssert(poppedViewControllers == [b, c])
        
        poppedViewController = stack.popViewControllerAnimated(animated: false)
        XCTAssert(stack.viewControllers == [a])
        XCTAssertNil(poppedViewController)
    }
    
    func testSetViewControllers() {
        
        let stack = StackViewController()
        stack.viewControllers = [a, b, c]
        stack.viewControllers = [b, e]
        XCTAssert(stack.viewControllers.count == 2)
        XCTAssert(stack.viewControllers == [b, e])
        
        stack.pushViewController(toViewController: c, animated: false)
        XCTAssert(stack.viewControllers == [b, e, c])
        
        stack.setViewControllers(viewControllers: [f, e, c], animated: false)
        XCTAssert(stack.viewControllers == [f, e, c])
    }
    
    func testChildViewControllers() {
        let stack = StackViewController()
        stack.viewControllers = [a, b, c]
        XCTAssert(stack.children.count == 3)
        XCTAssert(stack.children.last == c)
        
        stack.setViewControllers(viewControllers: [d, e], animated: false)
        XCTAssert(stack.children.count == 2)
        XCTAssert(stack.children.last == e)
        
        stack.pushViewController(toViewController: f, animated: false)
        XCTAssert(stack.children.count == 3)
        XCTAssert(stack.children.last == f)
        
        stack.popViewControllerAnimated(animated:false)
        XCTAssert(stack.children.count == 2)
        XCTAssert(stack.children.last == e)
        
        stack.popViewControllerAnimated(animated:false)
        XCTAssert(stack.children.count == 1)
        XCTAssert(stack.children.last == d)
                
        stack.viewControllers = [a, b, c, d]
        stack.viewControllers = [e, f, a]
        XCTAssert(stack.children.count == 3)
        
        // those are expected since we cannot reorder childViewControllers
        
        XCTAssert(stack.children == [a, e, f])
        
        stack.viewControllers = [a, b, c, d]
        stack.setViewControllers(viewControllers:[d, a, c], animated: false)
        
        XCTAssert(stack.children == [a, c, d])
        
        stack.viewControllers = []
        XCTAssert(stack.children.isEmpty)
    }
    
    func testUIViewControllerExtension() {
        var viewControllers = [UIViewController]()
        for _ in 0..<10 {
            let viewController = UIViewController()
            viewControllers.append(viewController)
            XCTAssert(viewController.stackViewController == nil)
        }
        
        let stack = StackViewController()
        
        stack.viewControllers = viewControllers
        for viewController in viewControllers {
            XCTAssertNotNil(viewController.stackViewController)
            XCTAssert(viewController.stackViewController! == stack)
        }
        
        stack.popViewControllerAnimated(animated:false)
        XCTAssertNil(viewControllers.last!.stackViewController)
        
        stack.viewControllers = []
        for viewController in viewControllers {
            XCTAssertNil(viewController.stackViewController)
        }
    }
    
}
