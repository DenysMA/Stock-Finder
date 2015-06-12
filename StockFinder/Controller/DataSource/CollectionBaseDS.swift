//
//  CollectionViewDS.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 31/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class CollectionBaseDS: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    typealias ClosureType = () -> ()
    private var entityName: String = ""
    private var predicate: NSPredicate?
    private var sortDescriptors: [NSSortDescriptor]?
    internal var collectionUpdates: [ClosureType]!
    internal var collectionView: UICollectionView!
    
    // MARK: - Set Up datasource for collection
    func setUpDataSourceForCollection(collection: UICollectionView, entityName: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) {
        
        self.entityName = entityName
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        collectionView = collection
        collectionView.dataSource = self
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(nil)
    }
    
    // MARK: - Update Fetch predicate
    func updatePredicate(predicate: NSPredicate) {
        
        self.predicate = predicate
        fetchedResultsController.fetchRequest.predicate = self.predicate
        fetchedResultsController.performFetch(nil)
        collectionView.reloadData()
    }
    
    // Shared context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        // Create fetch request
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        
        if let sortDescriptors = self.sortDescriptors {
            fetchRequest.sortDescriptors = sortDescriptors
        }
        
        if let predicate = self.predicate {
            fetchRequest.predicate = predicate
        }
        // Create fetchresults controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        }()
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![0] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    // MARK: - FetchResults Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // Create array of updates
        collectionUpdates = [ClosureType]()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            // Add the specific update to the array of closures
            
            switch type {
            case .Insert:
                collectionUpdates.append({
                    self.collectionView.insertItemsAtIndexPaths([newIndexPath!])
                })
            case .Delete:
                collectionUpdates.append( {
                    self.collectionView.deleteItemsAtIndexPaths([indexPath!])
                })
            case .Update:
                collectionUpdates.append( {
                    self.collectionView.reloadItemsAtIndexPaths([indexPath!])
                })
            case .Move:
                collectionUpdates.append( {
                    self.collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                })
            default:
                return
            }
            
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        // Copy collection updates to new variable
        var updates = self.collectionUpdates
        self.collectionView.performBatchUpdates( {
            
            // Execute closures
            for updateBlock in updates {
                updateBlock()
            }
            }, completion: nil)
    }

    
    
}