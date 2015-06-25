//
//  ImageCache.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 20/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Image Cache class to store news Images

import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    init() {
        inMemoryCache.countLimit = 15
    }
    
    // MARK: - Retreiving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        var data: NSData?
        
        // First try the memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        // Next try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // MARK: - Saving images
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        
        let path = pathForIdentifier(identifier)
        let fileExist = NSFileManager.defaultManager().fileExistsAtPath(path)
        var error: NSErrorPointer = nil
        
        // If the image is nil, delete images
        if image == nil {
            
            // Check if file exist, before trying to delete
            if fileExist {
                inMemoryCache.removeObjectForKey(path)
                if !NSFileManager.defaultManager().removeItemAtPath(path, error: error) {
                    NSLog("Error deleting image \(error.debugDescription)")
                }
            }
            
            return
        }
        
        // Store image if not exist
        if !fileExist {
            
            // Keep image in memory
            inMemoryCache.setObject(image!, forKey: path)
            
            // And in documents directory
            
            let data = UIImagePNGRepresentation(image!)
            
            if !data.writeToFile(path, atomically: true) {
                NSLog("Failed to save \(path) file \(error)")
            }
        }
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String {

        // Get path of documents directory
        var fileURL = CoreDataStackManager.sharedInstance().applicationDocumentsDirectory.URLByAppendingPathComponent(identifier.lastPathComponent)
        
        return fileURL.path!
    }
}
