//
//  CustomRefreshControl.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 15/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit

class CustomRefreshControl: UIRefreshControl {

    let refresh = UIImageView(image: UIImage(named: "refresh"))
    var topContentInset: CGFloat = 0
    var topContentInsetSaved: Bool = false
    var animating = false
    
    override init() {
        super.init()
        self.tintColor = UIColor.clearColor()
        refresh.contentMode = UIViewContentMode.Center
        refresh.frame = self.bounds
        self.insertSubview(refresh, atIndex: 0)
        
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let scrollView = self.superview as! UIScrollView
        if !topContentInsetSaved {
            topContentInset = scrollView.contentInset.top
            topContentInsetSaved = true
        }
        
        // saving own frame, that will be modified
        var newFrame = self.frame
        
        if scrollView.contentOffset.y < -topContentInset && refreshing {
            newFrame.origin.y = topContentInset == 0 ? -frame.height: scrollView.contentOffset.y
            refresh.hidden = false
        }
        else {
            newFrame.origin.y = -topContentInset
            refresh.hidden = true
            stopAnimation()
        }
        
        self.frame = newFrame
        refresh.frame = self.bounds
    }
    
    override func beginRefreshing() {
        refresh.hidden = false
        performAnimation()
        super.beginRefreshing()
    }
    
    override func endRefreshing() {
        refresh.hidden = true
        stopAnimation()
        super.endRefreshing()
    }
    
    func performAnimation() {
        if !animating {
            animating = true
            UIView.animateWithDuration(1.5, delay: 0, options:UIViewAnimationOptions.CurveLinear |  UIViewAnimationOptions.Repeat, animations: {
                self.refresh.transform = CGAffineTransformRotate(self.refresh.transform, CGFloat(M_PI_2))
                }, completion: nil)
        }
    }
    
    func stopAnimation() {
        refresh.layer.removeAllAnimations()
        animating = false
    }
    
}
