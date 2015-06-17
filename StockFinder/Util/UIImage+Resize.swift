//
//  UIImage+Resize.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 01/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  UIImage extension to support resizing

import UIKit

public extension UIImage {
    
    func resizeImage(size: CGSize) -> UIImage? {
        
        var size = size
        // if new size is not compatible with the current size adjust new size
        if self.size.width < size.width {
            size.width = self.size.width
        }
        if self.size.height < size.height {
            size.height = self.size.height
        }

        let image = self.CGImage
        let bitsPerComponent = CGImageGetBitsPerComponent(image)
        let bytesPerRow = CGImageGetBytesPerRow(image)
        let colorSpace = CGImageGetColorSpace(image)
        let bitmapInfo = CGImageGetBitmapInfo(image)
        
        let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
        
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh)
        
        CGContextDrawImage(context, CGRect(origin: CGPointZero, size: size), image)
        
        return UIImage(CGImage: CGBitmapContextCreateImage(context))
    }

}