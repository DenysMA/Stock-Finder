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
    var scrollView: UIScrollView!
    var attributedString: NSMutableAttributedString!
    var range: NSRange!
    var label: UILabel!
    
    override init() {
        super.init()
        self.tintColor = UIColor.clearColor()
        refresh.contentMode = UIViewContentMode.Center
        refresh.frame = self.bounds
        insertSubview(refresh, atIndex: 0)
        
        attributedString = NSMutableAttributedString(string:"Pull to refresh")
        range = NSRange(location: 0, length: count(attributedString.string))
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: range)
        
        performAnimation()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        refresh.layer.removeAllAnimations()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if refresh.layer.animationForKey("rotation") == nil {
            UIView.setAnimationsEnabled(true)
            performAnimation()
        }
        refresh.alpha =  refreshing ? 1 : self.subviews[1].subviews[1].alpha()
        refresh.layer.timeOffset = refresh.layer.convertTime(CACurrentMediaTime(), fromLayer:nil)
        refresh.layer.beginTime = CACurrentMediaTime()
        refresh.layer.speed = refreshing ? 1 : 0.3
        range = NSRange(location: 0, length: count(attributedString.string))
        attributedString.mutableString.replaceCharactersInRange(range, withString: refreshing ? "Refreshing" : "Pull to refresh")
        attributedTitle = attributedString
        
        scrollView = self.superview as! UIScrollView
        if !topContentInsetSaved {
            topContentInset = scrollView.contentInset.top
            topContentInsetSaved = true
        }
        
        // saving own frame, that will be modified
        var newFrame = self.frame
        if  trunc(scrollView.contentOffset.y) < -trunc(topContentInset) {
            newFrame.origin.y = topContentInset == 0 ? -frame.height: scrollView.contentOffset.y
            refresh.hidden = false
        }
        else {
            newFrame.origin.y = -topContentInset
            refresh.hidden = true
        }
        
        self.frame = newFrame
        refresh.frame = self.bounds
    }
    
    override func beginRefreshing() {
        super.beginRefreshing()
    }
    
    override func endRefreshing() {
        super.endRefreshing()
    }

    func performAnimation() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = M_PI * 2.0 * 2 * 1
        rotationAnimation.duration = 3.0
        rotationAnimation.cumulative = true
        rotationAnimation.repeatCount = Float.infinity
        refresh.layer.addAnimation(rotationAnimation, forKey: "rotation")
    }
    
}
