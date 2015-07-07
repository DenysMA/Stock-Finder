//
//  News.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 06/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

@objc(News)

class News: NSManagedObject {
    
    let mainSource = "yahoo.com"

    struct Keys {
        static let title = "title"
        static let guid = "guid"
        static let source = "source"
        static let credits = "credits"
        static let link = "link"
        static let imageURL = "imageURL"
        static let videoURL = "embededURL"
        static let summary = "description"
        static let symbol = "symbol"
        static let type = "type"
        static let date = "pubDate"
        static let extras = "extras"
    }
    
    // Managed variables
    @NSManaged var guid: String
    @NSManaged var title: String
    @NSManaged var source: String
    @NSManaged var credits: String?
    @NSManaged var link: String
    @NSManaged var symbol: String?
    @NSManaged var type: Int64
    @NSManaged var summary: String
    @NSManaged var imageURL: String?
    @NSManaged var videoURL: String?
    @NSManaged var imageState: Int64
    @NSManaged var date: NSDate
    @NSManaged var newsContent: Content?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Set image if exist
        if let image = YahooClient.Caches.imageCache.imageWithIdentifier(imageURL) {
            newsImage = image
            state = .Downloaded
        }
        else if let imageURL = imageURL {
            state = .New
        }
    }
    
    // MARK: - Initializer with dictionary
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("News", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        guid = dictionary[Keys.guid] as! String
        title = dictionary[Keys.title] as! String
        link = dictionary[Keys.link] as! String
        summary = dictionary[Keys.summary] as? String ?? ""
        
        if let stringLink = link.componentsSeparatedByString("*").last {
            link = stringLink.stringByRemovingPercentEncoding!
        }
        
        if let pubDate = dictionary[Keys.date] as? String {
            date = Formatter.getDateFromString(pubDate) ?? NSDate()
        }
        YahooClient.sharedInstance().prefetchMediaForNews(self)
        
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        if let imageURL = imageURL {
            YahooClient.Caches.imageCache.storeImage(nil, withIdentifier: imageURL)
        }
    }
    
    // MARK: - Merge method
    func mergeValues(dictionary: [String: AnyObject]) {

        videoURL = dictionary[Keys.videoURL] as? String ?? videoURL
        credits = dictionary[Keys.credits] as? String ?? credits
        if let source = dictionary[Keys.source] as? String {
            self.source = source
        }
        else {
            self.source = Formatter.getHostNameFromString(link)
            self.state = .Failed
        }
        if let imageURL = dictionary[Keys.imageURL] as? String {
            self.imageURL = Formatter.formatURL(imageURL)
        }
        
    }
    
    var isContentMainSource: Bool {
        if let range = link.rangeOfString(mainSource, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) {
            return true
        }
        return false
    }
    
    var newsImage: UIImage? {
        // Store image in cache and documents dir after it is downloaded
        didSet {
            
            // Image is valid then update state to downloaded
            if newsImage != nil && imageURL != nil {
                
                YahooClient.Caches.imageCache.storeImage(newsImage, withIdentifier: imageURL!)
                state = .Downloaded
            }
            else {
                
                // Image is invalid then update state to new or pending for dowloading
                state = .New
            }
        }
    }
    
    var isMediaDownloaded: Bool {
        if count(source) <= 1   {
            return false
        }
        return true
    }

    var newsType: NewsType {
        get {
            return NewsType(rawValue: self.type)!
        }
        set {
            self.type = newValue.rawValue
        }
    }
    
    var state: ImageState {
        get {
            return ImageState(rawValue: self.imageState)!
        }
        set {
            self.imageState = newValue.rawValue
        }
    }
    
}

// MARK: - Image State and News Type Enums

enum ImageState: Int64 {
    case New=0, Downloaded, Failed
}
enum NewsType: Int64 {
    case TopNews, CompanyNews, PressRelease
}