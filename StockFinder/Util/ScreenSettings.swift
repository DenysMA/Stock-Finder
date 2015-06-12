//
//  ScreenSettings.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 06/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Screen settings store global configuration used in all app

import UIKit

class ScreenSettings {
    
    static let SFUpColor = PropertyList.sharedInstance().stockColor("UP")
    static let SFDownColor = PropertyList.sharedInstance().stockColor("DOWN")
    static let SFLineSpacing = CGFloat(PropertyList.sharedInstance().lineSpacing())
    static let SFPreferedFontSize = CGFloat(PropertyList.sharedInstance().preferedFontSize())
    
    // Get screen size for a specific orientation
    class func sizeForOrientation(orientation: UIInterfaceOrientation) -> CGSize {
        
        var size = UIScreen.mainScreen().bounds.size
        let currentOrientation = UIApplication.sharedApplication().statusBarOrientation
        
        if currentOrientation.isPortrait && orientation.isLandscape || currentOrientation.isLandscape && orientation.isPortrait  {
            size = CGSizeMake(size.height, size.width)
        }
        return size
    }
}