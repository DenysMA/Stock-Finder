//
//  IndexMarketDS.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 31/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import CoreData
import UIKit

class IndexMarketDS: CollectionBaseDS, UICollectionViewDelegate {
    
    private var searchTask: NSURLSessionDataTask?
    
    weak var owner: MarketOverviewVC? {
        didSet {
            // Set predicate and descriptors
            let predicate = NSPredicate(format: "mainIndex == true and region == %i", Int64(owner!.regionControl.selectedSegmentIndex))
            let sortDescriptors = [NSSortDescriptor(key: "symbol", ascending: true)]
            setUpDataSourceForCollection(owner!.indexCollection, entityName: "Stock", predicate: predicate, sortDescriptors: sortDescriptors)
            owner?.indexCollection.delegate = self
        }
    }
    
    // MARK: - Collection Datasource
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let stock = fetchedResultsController.objectAtIndexPath(indexPath) as! Stock
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("indexCell", forIndexPath: indexPath) as! StockCollectionViewCell
        
        cell.symbolLabel.text = stock.company.name.uppercaseString
        cell.priceLabel.text = stock.price
        cell.changeAvgLabel.text = "(\(stock.changeAvg)%)"
        cell.changeAvgLabel.textColor = stock.change > 0 ? ScreenSettings.SFUpColor: ScreenSettings.SFDownColor
        
        return cell
    }

    // MARK: - Collection Delegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let stock = fetchedResultsController.objectAtIndexPath(indexPath) as! Stock
        owner!.delegate?.didSelectStock(stock.objectID)
    }
    
    // Update predicate
    func updatePredicate() {
        
        let predicate = NSPredicate(format: "mainIndex == true and region == %i", Int64(self.owner!.regionControl.selectedSegmentIndex))
        updatePredicate(predicate)
    }
    
    
    // MARK: -  Download Content
    func loadData(){
        
        let region = owner!.regionControl.selectedSegmentIndex
        owner?.state = .Loading
        
        // If task running, cancel task
        if let task = searchTask {
            
            task.cancel()
            searchTask = nil
            owner?.state = .Cancelled
        }
        
        searchTask = YahooClient.sharedInstance().getMarketSummary(region) { results, error in
            
            if let error = error {
                
                dispatch_async(dispatch_get_main_queue()){
                    // Set state and error and notify delegate
                    self.owner?.error = error
                    self.owner?.state = .Failed
                    self.owner?.delegate?.didFinishLoading()
                }
            }
            else if let results = results {
                
                let items = self.getAllStocks()
                
                for dictionary in results {
                    
                    if self.searchTask == nil {
                        return
                    }
                    
                    // Check if object exists
                    var symbol = dictionary[Stock.Keys.symbol] as! String
                    let results = items.filter() { $0.symbol == symbol }
                    
                    if results.isEmpty {
                        // Create new object
                        Stock(dictionary: dictionary, context: self.sharedContext)
                    }
                    else {
                        // Update object
                        results.first!.mergeValues(dictionary)
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    // Set state and notify delegate
                    self.owner?.error = nil
                    self.owner?.state = State.Loaded
                    self.owner?.delegate?.didFinishLoading()
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
    // MARK: - Get all stock entities
    func getAllStocks() -> [Stock] {
        
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Stock")
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        // Check for Errors
        if error != nil {
            NSLog("Error in fectchWatchList(): \(error)")
        }
        return results as? [Stock] ?? [Stock]()
    }

}