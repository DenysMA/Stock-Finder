//
//  WatchSearchListVC.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 05/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

protocol WatchListDelegate {
    
    func didSelectStock(stockID: NSManagedObjectID)
    func didFinishLoading()
}

class WatchSearchListVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var message: UILabel!
    
    internal var delegate: WatchListDelegate?
    internal var state = State.Initiated
    internal var error: String?
    private let watchSearchCollectionDS = WatchSearchDS()
    
    // Reordering cells
    private var snapshot: UIView?
    private var newCell: WatchCollectionViewCell?
    private var currentCell: WatchCollectionViewCell?
    private var currentStock: Stock?
    private var newStockPosition: Stock?
    private var translation = CGPointZero
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up datasource
        watchSearchCollectionDS.owner = self
    }
    
    // Collection view content size
    var size: CGSize {
        get {
            let messageHeight: CGFloat = message.hidden ? 0 : message.sizeThatFits(CGSizeZero).height
            return CGSizeMake(collectionView.collectionViewLayout.collectionViewContentSize().width ,
                collectionView.collectionViewLayout.collectionViewContentSize().height + messageHeight)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate item size orientation dependent
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        let minimumWidth: CGFloat = 320.0
        var preferedWidth = UIScreen.mainScreen().bounds.width * 0.48
        
        if preferedWidth < minimumWidth || minimumWidth == UIScreen.mainScreen().bounds.width {
            preferedWidth = UIScreen.mainScreen().bounds.width - 20
        }
        
        flowLayout.itemSize = CGSize(width: preferedWidth, height: 80)
        flowLayout.invalidateLayout()
    }
    
    // MARK: - Load content
    func loadStockInfo() {
        
        watchSearchCollectionDS.loadData()
    }
    
    // MARK: - UnWatch
    @IBAction func unWatch(sender: UIButton) {
        
        // Get collection view object
        let watchButtonPosition = sender.convertPoint(CGPointZero, toView: collectionView)
        var stock = watchSearchCollectionDS.getObjectForPoint(watchButtonPosition)
        // Update object
        stock?.watched = false
        stock?.order = 0
        watchSearchCollectionDS.expandedIndexPath = nil
        // Save changes
        CoreDataStackManager.sharedInstance().saveContext()
        // Call delegate to refresh parent controller
        loadStockInfo()
    }
    
    // MARK: - Swipe Item to Delete
    @IBAction func swipeHandler(sender: UISwipeGestureRecognizer) {
        
        // Get button position
        let position = sender.locationInView(collectionView)
        
        // Get indexPath for position
        if let indexPath = collectionView.indexPathForItemAtPoint(position) {
            
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! WatchCollectionViewCell
            let currentIndexPath = watchSearchCollectionDS.expandedIndexPath
            
            if let currentIndexPath = currentIndexPath, let previousCell = collectionView.cellForItemAtIndexPath(currentIndexPath) as? WatchCollectionViewCell {
                
                if currentIndexPath != indexPath && sender.direction == UISwipeGestureRecognizerDirection.Left {
                    watchSearchCollectionDS.expandedIndexPath = indexPath
                    previousCell.updateMenuOptions()
                    cell.updateMenuOptions()
                }
                else if currentIndexPath == indexPath && sender.direction == UISwipeGestureRecognizerDirection.Right {
                    watchSearchCollectionDS.expandedIndexPath = nil
                    cell.updateMenuOptions()
                }
            }
            else if sender.direction == UISwipeGestureRecognizerDirection.Left {
                watchSearchCollectionDS.expandedIndexPath = indexPath
                cell.updateMenuOptions()
            }
        }
    }
    
    // MARK: - Long press to reorder item
    @IBAction func longPressHandler(gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
            
        case UIGestureRecognizerState.Began:
            
            // Get location in collectionView
            let location = gesture.locationInView(collectionView)
            // Get indexPath
            if let indexPath = collectionView.indexPathForItemAtPoint(location) {
                translation = location
                let currentCell = collectionView.cellForItemAtIndexPath(indexPath) as!WatchCollectionViewCell
                let positionInCell = currentCell.convertPoint(location, fromView: collectionView)
                // Check if touch location is inside valid area
                if !currentCell.orderButton.frame.contains(positionInCell) {
                    return
                }
                // Create snapshot
                snapshot = createCellSnapshot(currentCell)
                snapshot?.center = currentCell.center
                snapshot?.alpha = 0
                currentStock = watchSearchCollectionDS.getObjectForPoint(location)
                collectionView.addSubview(snapshot!)
                self.currentCell = currentCell
                
                // Fade out current cell
                UIView.animateWithDuration(0.25, animations: {
                    self.snapshot?.transform = CGAffineTransformMakeScale(1.1, 1.1)
                    self.snapshot?.alpha = 1
                    currentCell.alpha = 0}){ finished in
                    currentCell.hidden = true
                }
            }
        case UIGestureRecognizerState.Changed:
            
            if let snapshot = snapshot {
                
                // Get location of new item
                let newLocation = gesture.locationInView(collectionView)
                translation = CGPointMake(newLocation.x - translation.x , newLocation.y - translation.y)
                snapshot.center = CGPointMake(snapshot.center.x + translation.x , snapshot.center.y + translation.y)
                newCell?.alpha = 1
                
                // Animate next item
                if let newIndexPath = collectionView.indexPathForItemAtPoint(newLocation) {
                    newCell = collectionView.cellForItemAtIndexPath(newIndexPath) as? WatchCollectionViewCell
                    newCell?.alpha = 0.4
                    self.newStockPosition = watchSearchCollectionDS.getObjectForPoint(newLocation)
                }
                translation = newLocation
            }
        case UIGestureRecognizerState.Ended:
            
            // Update order
            if let currentStock = currentStock, let newStockPosition = newStockPosition, let snapshot = snapshot {
                if currentStock != newStockPosition {
                    updateStockOrder(currentStock, newOrder: newStockPosition.order)
                }
            }
            
            snapshot?.removeFromSuperview()
            restoreGestureValues()
            
        default:
            
            snapshot?.removeFromSuperview()
            collectionView.reloadSections(NSIndexSet(index: 0))
            restoreGestureValues()
        }
    }
    
    // Reset reordering values
    func restoreGestureValues() {
        translation = CGPointZero
        currentCell?.alpha = 1
        currentCell?.hidden = false
        newCell?.alpha = 1
        currentCell = nil
        newCell = nil
        snapshot = nil
        currentStock = nil
        newStockPosition = nil
    }
    
    // MARK: - View Snapshot
    func createCellSnapshot(cellView: WatchCollectionViewCell) -> UIView {

        // Render view to an image
        UIGraphicsBeginImageContext(cellView.bounds.size)
        cellView.drawViewHierarchyInRect(cellView.bounds, afterScreenUpdates: true)
        let cellImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let snapshot = UIImageView(image: cellImage)
        snapshot.layer.masksToBounds = false
        snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0)
        snapshot.layer.shadowOpacity = 0.7
        return snapshot
    }
    
    // MARK: - Update order
    func updateStockOrder(stock: Stock, newOrder: Int64) {
        var stocks = watchSearchCollectionDS.fetchedResultsController.fetchedObjects! as! [Stock]
        var filterValidation: (stock: Stock) -> (Bool)
        var filteredStocks: [Stock]!
        var orderChangeFactor = 0
        
        if newOrder > stock.order {
            orderChangeFactor = -1
            filterValidation = { ($0.order > stock.order && $0.order <= newOrder) }
        }
        else {
            orderChangeFactor = 1
            filterValidation = { ($0.order < stock.order && $0.order >= newOrder) }
        }
        
        filteredStocks = stocks.filter(filterValidation)
        for stock in filteredStocks {
            stock.order = stock.order + orderChangeFactor
        }
        stock.order = newOrder
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
}
