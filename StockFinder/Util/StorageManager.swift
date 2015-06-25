//
//  StorageManager.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 24/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation
import CoreData

class StorageManager: NSObject {
    
    class func sharedInstance() -> StorageManager {
        
        struct Singleton {
            static var sharedInstance = StorageManager()
        }
        return Singleton.sharedInstance
    }
    
    func storageOfEntity(entityName: String) -> Int {
        
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.includesPropertyValues = false
        fetchRequest.includesSubentities = false
        let count = CoreDataStackManager.sharedInstance().managedObjectContext!.countForFetchRequest(fetchRequest, error: error)
        // Check for Errors
        if count == NSNotFound {
            return 0
        }
        return count
    }
    
    func clearOldNews() {
        
        let error: NSErrorPointer = nil
        let maxItems = PropertyList.sharedInstance().maxItemsForNews()
        let storedItems = storageOfEntity("News")
        if storedItems > maxItems {
            
            let fetchRequest = NSFetchRequest(entityName: "News")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            fetchRequest.fetchLimit = storedItems - maxItems
    
            let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            privateContext.persistentStoreCoordinator = CoreDataStackManager.sharedInstance().managedObjectContext!.persistentStoreCoordinator
            let notification = NSNotificationCenter.defaultCenter()
            notification.addObserver(self, selector: "managedObjectContextDidSave:", name: NSManagedObjectContextDidSaveNotification, object: privateContext)
            
            privateContext.performBlockAndWait() {
                if let results = privateContext.executeFetchRequest(fetchRequest, error: error) as? [News] {
                    for item in results {
                        privateContext.deleteObject(item)
                    }
                    if privateContext.hasChanges {
                        privateContext.save(error)
                    }
                }
            }
        }
    }
    
    func managedObjectContextDidSave(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().managedObjectContext!.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
}