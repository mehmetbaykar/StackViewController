//
//  StackViewControllerProtocol.swift
//  StackViewControllerDemo
//
//  Created by guojiubo on 9/22/15.
//  Copyright (c) 2015 CocoaWind. All rights reserved.
//

import UIKit


public protocol StackViewControllerProtocol {
    
    func nextViewControllerOnStackViewController(stackViewController: StackViewController) -> UIViewController?
    
    func scrollViewOnStackViewController(stackViewController: StackViewController) -> UIScrollView?
    
}


public extension StackViewControllerProtocol {
    
    func nextViewControllerOnStackViewController(stackViewController: StackViewController) -> UIViewController? {
        return nil
    }
    
    func scrollViewOnStackViewController(stackViewController: StackViewController) -> UIScrollView? {
        return nil
    }
    
}
