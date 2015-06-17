//
//  CustomRefreshControl.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 15/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit

class CustomRefreshControl: UIRefreshControl {

    var topContentInset: CGFloat = 0
    var topContentInsetSaved: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let scrollView = self.superview as! UIScrollView
        
        if !topContentInsetSaved {
            topContentInset = scrollView.contentInset.top
            topContentInsetSaved = true
        }
        
        // saving own frame, that will be modified
        var newFrame = self.frame
        
        if scrollView.contentOffset.y < -newFrame.size.height {
            newFrame.origin.y = scrollView.contentOffset.y
        }
        else {
            newFrame.origin.y = -topContentInset
        }
        
        self.frame = newFrame
    }
}
