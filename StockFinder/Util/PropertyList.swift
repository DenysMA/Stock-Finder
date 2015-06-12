//
//  PropertyList.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 01/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Helper class to get values from a plist file

import Foundation
import UIKit

class PropertyList {
    
    // Dictionary of values
    private var dictionary: NSDictionary!
    
    class func sharedInstance() -> PropertyList {
        
        struct Singleton {
            static var sharedInstance = PropertyList()
        }
        
        return Singleton.sharedInstance
    }
    
    // Initializer
    init() {
        let path = NSBundle.mainBundle().pathForResource("StockFinder", ofType: "plist")!
        dictionary = NSDictionary(contentsOfFile: path)
    }
    
    // MARK: - Common properties methods
    
    // Get items to be presented in Stock Details VC
    func stockDetailsItems() -> [[String: String]] {
        
        return dictionary.objectForKey("StockDetail") as! [[String: String]]
    }
    
    // Get global color to be used with positive and negative values
    func stockColor(value: String) -> UIColor {
        var rgbColor: String!
        
        if value == "UP" {
            rgbColor = dictionary.objectForKey("stockUp") as! String
        }
        else {
            rgbColor = dictionary.objectForKey("stockDown") as! String
        }
        
        let colors = rgbColor.componentsSeparatedByString(",") as [NSString]
        return UIColor(red: CGFloat(colors[0].floatValue/255), green: CGFloat(colors[1].floatValue/255), blue: CGFloat(colors[2].floatValue/255), alpha: CGFloat(colors[3].floatValue))
    }
    
    // Get lineSpacing according to device
    func lineSpacing() -> Int {
        
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            return dictionary.objectForKey("minLineSpacing")!.integerValue
        }
        return dictionary.objectForKey("maxLineSpacing")!.integerValue
    }
    
    // Get prefered font Size for Web Content according to device
    func preferedFontSize() -> Int {
        
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            return dictionary.objectForKey("minFontSize")!.integerValue
        }
        return dictionary.objectForKey("maxFontSize")!.integerValue
    }
        
}