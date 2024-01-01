//
//  StackViewController.swift
//  StackViewControllerDemo
//
//  Created by guojiubo on 8/26/15.
//  Copyright (c) 2015 CocoaWind. All rights reserved.
//

import UIKit

public class StackViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Public properties
    
    /// Horizontal slide transition duration.
    public var animationDuration = 0.2
    
    /// The threshold to trigger a push or pop through pan gesture.
    public var threshold = 0.15 {
        willSet {
            self.threshold = min(1, max(0, newValue))
        }
    }
    
    /// Shadow customization
    public var shadowColor = UIColor.lightGray
    public var shadowOffset = CGSizeMake(-2, 0)
    public var shadowOpacity = 0.5
    
    /// The current view controller stack.
    public var viewControllers: [UIViewController] {
        get {
            return self.stack
        }
        set {
            self.setViewControllers(viewControllers: newValue, animated: false)
        }
    }
    
    /// The top view controller on the stack.
    public var topViewController: UIViewController? {
        return self.viewControllers.last
    }
    
    /// The root view controller on the stack.
    public var rootViewController: UIViewController? {
        return self.viewControllers.first
    }
    
    
    // MARK: - Initializations
    
    /// Convenience method pushes the root view controller without animation.
    public required init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        
        self.pushViewController(toViewController: rootViewController, animated: false)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - APIs
    
    /// If animated, then simulate a push or pop depending on whether the new top view controller was previously in the stack.
    public func setViewControllers(viewControllers: [UIViewController], animated: Bool) {
        let fromViewController = self.topViewController
        
        if viewControllers.isEmpty {
            // clean stack
            for viewController in self.viewControllers {
                viewController.willMove(toParent: nil)
                if viewController == fromViewController {
                    viewController.view.removeFromSuperview()
                }
                viewController.removeFromParent()
            }
            self.stack.removeAll(keepingCapacity: false)
            
            return
        }
        
        let toViewController = viewControllers.last!
        
        // manage view controller stack
        for viewController in viewControllers {
            if self.viewControllers.contains(viewController) {
                continue
            }
            if viewController == toViewController {
                continue
            }
            self.addChild(viewController)
            viewController.didMove(toParent: self)
        }
        
        for viewController in self.viewControllers {
            if viewControllers.contains(viewController) {
                continue
            }
            if viewController == fromViewController {
                continue
            }
            viewController.willMove(toParent: nil)
            viewController.removeFromParent()
        }
        
        let previousStack = self.stack
        self.stack = viewControllers
        
        if fromViewController == toViewController {
            // no transition performed
            return
        }
        
        if previousStack.contains(toViewController) {
            // new top item alread on the stack, use a pop transition
            
            self.popFromViewController(fromViewController: fromViewController!, toViewController: toViewController, animated: animated) {
                if let fromViewController = fromViewController {
                    if !self.stack.contains(fromViewController) {
                        fromViewController.willMove(toParent: nil)
                        fromViewController.view.removeFromSuperview()
                        fromViewController.removeFromParent()
                    }
                    else {
                        fromViewController.view.removeFromSuperview()
                    }
                }
            }
            
            return
        }
        
        // use a push transition
        
        self.addChild(toViewController)
        
        self.pushFromViewController(fromViewController: fromViewController, toViewController: toViewController, animated: animated) {
            if let fromViewController = fromViewController {
                if !self.stack.contains(fromViewController) {
                    fromViewController.willMove(toParent: nil)
                    fromViewController.view.removeFromSuperview()
                    fromViewController.removeFromParent()
                }
                else {
                    fromViewController.view.removeFromSuperview()
                }
            }
            
            toViewController.didMove(toParent: self)
        }
        
    }
    
    
    /// Uses a horizontal slide transition. Has no effect if the view controller is already in the stack.
    public func pushViewController(toViewController: UIViewController, animated: Bool) {
        if self.viewControllers.contains(toViewController) {
            print("the view controller is already on the stack")
            return
        }
        
        let fromViewController = self.topViewController
        
        self.addChild(toViewController)
        self.stack.append(toViewController)
        
        self.pushFromViewController(fromViewController: fromViewController, toViewController: toViewController, animated: animated) {
            fromViewController?.view.removeFromSuperview()
            
            toViewController.didMove(toParent: self)
        }
    }
    
    /// Returns the popped controller.
    @discardableResult
    public func popViewControllerAnimated(animated: Bool) -> UIViewController? {
        if self.viewControllers.count < 2 {
            return nil
        }
        
        let fromViewController = self.topViewController!
        
        let topIndex = self.viewControllers.firstIndex(of: fromViewController)
        let toViewController = self.viewControllers[topIndex! - 1]
        
        fromViewController.willMove(toParent: nil)
        
        self.popFromViewController(fromViewController: fromViewController, toViewController: toViewController, animated: animated) {
            fromViewController.view.removeFromSuperview()
            fromViewController.removeFromParent()
            
            self.stack.removeLast()
        }
        
        return fromViewController
    }
    
    /// Pops until there's only a single view controller left on the stack. Returns the popped controllers.
    public func popToRootViewControllerAnimated(animated: Bool) -> [UIViewController] {
        if self.viewControllers.count < 2 {
            return []
        }
        
        let stackAfterPopped = [self.rootViewController!]
        let popped = Array(self.viewControllers[1..<self.viewControllers.count])
        
        self.setViewControllers(viewControllers: stackAfterPopped, animated: animated)
        
        return popped
    }
    
    /// Pops view controllers until the one specified is on top. Returns the popped controllers.
    public func popToViewController(viewController: UIViewController, animated: Bool) -> [UIViewController] {
        let index = self.viewControllers.firstIndex(of:viewController)
        if index == nil {
            let popped = self.viewControllers
            self.setViewControllers(viewControllers: [], animated: animated)
            return popped
        }
        
        let stackAfterPopped = Array(self.viewControllers[0...index!])
        let popped = Array(self.viewControllers[index! + 1..<self.viewControllers.count])
        
        self.setViewControllers(viewControllers: stackAfterPopped, animated: animated)
        
        return popped
    }
    
    // MARK: - Private properties
    
    private var stack = [UIViewController]()
    
    private weak var previousViewController: UIViewController?
    private weak var currentViewController: UIViewController?
    private weak var nextViewController: UIViewController?
    
    private var panGestureRecognizer: StackPanGestureRecognizer!
    
    // MARK: - View life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureRecognizer = StackPanGestureRecognizer()
        gestureRecognizer.delegate = self
        gestureRecognizer.addTarget(self, action: #selector(StackViewController.handlePanGesture(recognizer:)))
        self.view.addGestureRecognizer(gestureRecognizer)
        self.panGestureRecognizer = gestureRecognizer
    }
    
    // MARK: - Pan gesture
    
    @objc func handlePanGesture(recognizer: StackPanGestureRecognizer) {
        if recognizer.direction == .Pop {
            self.handlePopGesture(recognizer: recognizer)
        }
        else if recognizer.direction == .Push {
            self.handlePushGesture(recognizer: recognizer)
        }
    }
    
    func handlePushGesture(recognizer: StackPanGestureRecognizer) {
        if recognizer.state == .began {
            self.currentViewController = nil
            self.nextViewController = nil
            
            guard let dataSource = self.topViewController as? StackViewControllerProtocol else {
                recognizer.state = .failed
                return
            }
            
            guard let nextViewController = dataSource.nextViewControllerOnStackViewController(stackViewController: self) else {
                recognizer.state = .failed
                return
            }
            
            self.nextViewController = nextViewController
            self.currentViewController = self.topViewController
            
            self.addChild(nextViewController)
            nextViewController.view.frame = self.view.bounds
            nextViewController.view.frame.origin.x = CGRectGetWidth(self.view.bounds)
            nextViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.insertSubview(nextViewController.view, aboveSubview: self.currentViewController!.view)
            nextViewController.didMove(toParent: self)
            
            self.applyShadowToView(view: nextViewController.view)
            
            return
        }
        
        guard let toViewController = self.nextViewController, let fromViewController = self.currentViewController else {
            recognizer.state = .failed
            return
        }
        
        if recognizer.state == .changed {
            let translation = recognizer.translation(in: self.view)
            let progress = translation.x/CGRectGetWidth(self.view.bounds)
            
            toViewController.view.frame.origin.x = min(CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds) + translation.x)
            
            fromViewController.view.frame.origin.x = min(0, progress * CGRectGetWidth(self.view.bounds)/3)
            
            return
        }
        
        if recognizer.state == .cancelled || recognizer.state == .ended {
            let movedDistance = toViewController.view.frame.origin.x
            let movedPercentage = Double(movedDistance/CGRectGetWidth(self.view.bounds))
            
            if 1 - movedPercentage >= self.threshold {
                // trigger push
                UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
                    toViewController.view.frame.origin.x = 0
                    fromViewController.view.frame.origin.x = -CGRectGetWidth(self.view.bounds)/3
                    }, completion: { (finished) -> Void in
                        fromViewController.view.removeFromSuperview()
                        
                        self.stack.append(toViewController)
                })
                
                return
            }
            
            // cancel push
            UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
                toViewController.view.frame.origin.x = CGRectGetWidth(self.view.bounds)
                fromViewController.view.frame.origin.x = 0
                }, completion: { (finished) -> Void in
                    toViewController.willMove(toParent: nil)
                    toViewController.view.removeFromSuperview()
                    toViewController.removeFromParent()
            })
        }
    }
    
    func handlePopGesture(recognizer: StackPanGestureRecognizer) {
        if recognizer.state == .began {
            self.currentViewController = nil
            self.previousViewController = nil
            
            guard self.viewControllers.count >= 2 else {
                recognizer.state = .failed
                return
            }
            
            self.previousViewController = self.viewControllers[self.viewControllers.count - 2]
            self.currentViewController = self.topViewController
            
            self.previousViewController!.view.frame = self.view.bounds
            self.previousViewController!.view.frame.origin.x = -CGRectGetWidth(self.view.bounds)/3
            self.previousViewController!.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.insertSubview(self.previousViewController!.view, belowSubview: self.currentViewController!.view)
            
            self.applyShadowToView(view: self.currentViewController!.view)
            
            return
        }
        
        guard let toViewController = self.previousViewController, let fromViewController = self.currentViewController else {
            recognizer.state = .failed
            return
        }
        
        if recognizer.state == .changed {
            let translation = recognizer.translation(in: self.view)
            let progress = translation.x/CGRectGetWidth(self.view.bounds)
            
            toViewController.view.frame.origin.x = max(-CGRectGetWidth(self.view.bounds)/3, -CGRectGetWidth(self.view.bounds)/3 + CGRectGetWidth(self.view.bounds)/3 * progress)
            fromViewController.view.frame.origin.x = max(0, translation.x)
            
            return
        }
        
        if recognizer.state == .cancelled || recognizer.state == .ended {
            let movedDistance = fromViewController.view.frame.origin.x
            let movedPercentage = Double(movedDistance/CGRectGetWidth(self.view.bounds))
            
            if movedPercentage >= self.threshold {
                // POP
                UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
                    toViewController.view.frame.origin.x = 0
                    fromViewController.view.frame.origin.x = CGRectGetWidth(self.view.bounds)
                    }, completion: { (finished) -> Void in
                        fromViewController.willMove(toParent: nil)
                        fromViewController.view.removeFromSuperview()
                        fromViewController.removeFromParent()
                        
                        self.stack.removeLast()
                })
                
                return
            }
            
            // cancel POP
            UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
                toViewController.view.frame.origin.x = -CGRectGetWidth(self.view.bounds)/3
                fromViewController.view.frame.origin.x = 0
                }, completion: { (finished) -> Void in
                    toViewController.view.removeFromSuperview()
            })
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.panGestureRecognizer.state != .failed
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let dataSource = self.topViewController as? StackViewControllerProtocol else {
            self.panGestureRecognizer.scrollView = nil
            return otherGestureRecognizer.view is UIScrollView
        }
        
        guard let scrollView = dataSource.scrollViewOnStackViewController(stackViewController: self) else {
            self.panGestureRecognizer.scrollView = nil
            return otherGestureRecognizer.view is UIScrollView
        }
        
        self.panGestureRecognizer.scrollView = scrollView
        return true
    }
    
    // MARK: - Interface orientations
    public override var shouldAutorotate: Bool{
        return self.topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }
    
 
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return self.topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
   
    
    // MARK: - Private methods
    
    private func makePopTransitionFromViewController(fromViewController: UIViewController, toViewController: UIViewController) -> () -> Void {
        toViewController.view.frame.origin.x = -CGRectGetWidth(self.view.bounds)/3
        
        return {
            toViewController.view.frame.origin.x = 0
            fromViewController.view.frame.origin.x = CGRectGetWidth(self.view.bounds)
        }
    }
    
    private func makePushTransitionFromViewController(fromViewController: UIViewController?, toViewController: UIViewController) -> () -> Void {
        toViewController.view.frame.origin.x = CGRectGetWidth(self.view.bounds)
        
        return {
            toViewController.view.frame.origin.x = 0
            fromViewController?.view.frame.origin.x = -CGRectGetWidth(self.view.bounds)/3
        }
    }
    
    private func pushFromViewController(fromViewController: UIViewController?, toViewController: UIViewController, animated: Bool, completion:  @escaping  () -> Void) {
        toViewController.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))
        toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        guard let fromViewController = fromViewController else {
            self.view.addSubview(toViewController.view)
            completion()
            return
        }
        
        self.view.insertSubview(toViewController.view, aboveSubview: fromViewController.view)
        
        let animations = self.makePushTransitionFromViewController(fromViewController: fromViewController, toViewController: toViewController)
        
        if !animated {
            animations()
            completion()
            return
        }
        
        UIView.animate(withDuration: self.animationDuration, animations: animations, completion: { (finished) -> Void in
            completion()
        })
    }
    
    private func popFromViewController(fromViewController: UIViewController, toViewController: UIViewController, animated: Bool,completion:  @escaping () -> Void) {
        toViewController.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))
        toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.view.insertSubview(toViewController.view, belowSubview: fromViewController.view)
        
        let animations = self.makePopTransitionFromViewController(fromViewController: fromViewController, toViewController: toViewController)
        
        if !animated {
            animations()
            completion()
            return
        }
        
        UIView.animate(withDuration: self.animationDuration, animations: animations, completion: { (finished) -> Void in
            completion()
        })
    }
    
    private func applyShadowToView(view: UIView) {
        let path = UIBezierPath(rect: view.bounds)
        view.layer.masksToBounds = false
        view.layer.shadowColor = self.shadowColor.cgColor
        view.layer.shadowOffset = self.shadowOffset
        view.layer.shadowOpacity = Float(self.shadowOpacity)
        view.layer.shadowPath = path.cgPath
    }
    
}

// MARK: - UIViewController extension

public extension UIViewController {
    
    /// If this view controller has been push onto a stack view controller, return it.
    var stackViewController: StackViewController? {
        var parent = self.parent
        while parent != nil {
            if parent is StackViewController {
                return parent as? StackViewController
            }
            parent = parent?.parent
        }
        return nil
    }
}
