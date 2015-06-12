//
//  SFView.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 05/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Custom View with black gradient

import UIKit

class SFView: UIView {

    private let gradient = CAGradientLayer()
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        gradient.frame = self.bounds
        gradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        self.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = self.bounds
    }

}
