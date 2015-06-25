//
//  ImageDownloader.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 22/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreGraphics

// MARK : Image Downloader operation

class ImageDownloader: NSOperation {
    
    // Declare photo property
    let newsItem: News
    
    // Initializer with Photo object
    init(newsItem: News) {
        self.newsItem = newsItem
    }
    
    // Work to perform by the operation
    override func main() {
        
        // Check if operation is cancelled
        if self.cancelled {
            return
        }
        
        // Start downloading image
        let imageData = NSData(contentsOfURL:NSURL(string: self.newsItem.imageURL!)!)
        
        // Check if operation was cancelled before setting the image
        if self.cancelled {
            return
        }

        // If image data is valid then set image to news Image. (This will cause the image to be stored and it will update Photo.state property)
        if imageData?.length > 0 {
            
            var image = UIImage(data:imageData!)
            let width = ScreenSettings.sizeForOrientation(UIInterfaceOrientation.Portrait).width
            
            // Resize image downloaded according to screen size
            if let resizedImage = image!.resizeImage(CGSizeMake(width, width/2)) {
                image = resizedImage
            }
            else {
                NSLog("image not resized \(self.newsItem.imageURL)")
            }
            self.newsItem.newsImage = image
        }
        else
        {
            // If the image data is invalid then update state property to Failed
            self.newsItem.state = .Failed
        }
    }
}

// MARK : Pending Operations

class PendingOperations {
    
    // Create a dictionary to keep track of the downloads or operations in execution
    lazy var downloadsInProgress = [NSIndexPath:NSOperation]()
    
    // Create a queue to process all the downloads
    lazy var downloadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Download Image queue"
        return queue
        }()
}