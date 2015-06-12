//
//  WatchSearchDS.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 04/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class WatchSearchDS: CollectionBaseDS, UICollectionViewDelegate {
    
    weak var owner: WatchSearchListVC?{
        didSet {
            
            // Set predicate and descriptors
            let predicate = NSPredicate(format: "watched == true")
            let sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            
            // Set up datasource
            setUpDataSourceForCollection(owner!.collectionView, entityName: "Stock", predicate: predicate, sortDescriptors: sortDescriptors)
            // Set delegate
            owner?.collectionView.delegate = self
        }
    }
    
    internal var expandedIndexPath: NSIndexPath?
    private var searchTask: NSURLSessionDataTask?

    // MARK: - Download Content
    func loadData(){
        
        // Cancel current task if exists
        if let task = searchTask {
            
            task.cancel()
            searchTask = nil
        }
        
        var symbols = [String]()
        
        // Get list of stock symbols in WatchList
        for stock in self.fetchedResultsController.fetchedObjects as! [Stock]
        {
            symbols.append(stock.symbol)
        }
        
        if !symbols.isEmpty {
            
            // Set loading state
            owner?.state = State.Loading
            
            searchTask = YahooClient.sharedInstance().getQuotes(",".join(symbols)){ results, error in
                
                if let error = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        // Set state and error
                        self.owner?.error = error
                        self.owner?.state = State.Failed
                        // Notify delegate
                        self.owner?.delegate?.didFinishLoading()
                    }
                }
                    
                else if let results = results {
                    
                    for stock in self.fetchedResultsController.fetchedObjects as! [Stock] {
                        
                        if self.searchTask == nil {
                            return
                        }
                        
                        // Look if stock already exists
                        let stockDict = results.filter() { dictionary in
                            
                            if let symbol = dictionary[Stock.Keys.symbol] as? String {
                                return symbol == stock.symbol
                            }
                            return false
                        }
                        
                        // Update stock prices
                        if let dictionary = stockDict.first {
                            stock.mergeValues(dictionary)
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
        else {
            // Set state and notify delegate
            owner?.error = nil
            owner?.state = State.Loaded
            owner?.delegate?.didFinishLoading()
        }
    }

    // MARK: - Collection DataSource
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let stock = fetchedResultsController.objectAtIndexPath(indexPath) as! Stock
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("stockCell", forIndexPath: indexPath) as! WatchCollectionViewCell
        
        cell.symbolLabel.text = stock.symbol
        cell.exchangeLabel.text = stock.exchange.uppercaseString
        cell.companyLabel.text = stock.company.name
        cell.priceLabel.text = stock.price
        cell.changeLabel.text = "\(stock.change)"
        cell.changeAvgLabel.text = "\(stock.changeAvg)%"
        cell.changeLabel.textColor = stock.change > 0 ? ScreenSettings.SFUpColor: ScreenSettings.SFDownColor
        cell.changeAvgLabel.textColor = cell.changeLabel.textColor
        cell.hidden = false
        
        if expandedIndexPath == indexPath {
            // Show delete button
            cell.watchButtonConstraint.constant = 55.0
        }
        else {
            // Hide delete button
            cell.watchButtonConstraint.constant = 0
        }
        
        return cell
    }
    
    // MARK: - Collection Delegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let stock = fetchedResultsController.objectAtIndexPath(indexPath) as! Stock
        owner?.delegate?.didSelectStock(stock.objectID)
        
        expandedIndexPath = nil
        collectionView.reloadData()
    }
    
    // MARK: - Object for point
    func getObjectForPoint(position:CGPoint) -> Stock? {
        
        if let indexPath = owner!.collectionView.indexPathForItemAtPoint(position) {
            return fetchedResultsController.objectAtIndexPath(indexPath) as? Stock
        }
        return nil
    }

}