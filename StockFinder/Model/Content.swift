//
//  Content.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 22/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation
import CoreData

@objc(Content)

class Content: NSManagedObject {
    
    struct Keys {
        static let content = "content"
    }
    
    @NSManaged var htmlContent: NSData
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: - Initializer with dictionary
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Content", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        htmlContent = dictionary[Keys.content] as! NSData
    }
    
}