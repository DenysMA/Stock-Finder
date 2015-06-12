    //
//  MarketOverviewDS.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 04/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class MarketOverviewDS: CollectionBaseDS, UICollectionViewDelegate {
    
    weak var owner: MarketOverviewVC? {
        didSet {
            // Set predicate and descriptors
            let predicate = NSPredicate(format: "mainIndex == false and region == %i", owner!.regionControl.selectedSegmentIndex)
            let sortDescriptors = [NSSortDescriptor(key: "symbol", ascending: true)]
            // Set up datasource
            setUpDataSourceForCollection(owner!.marketCollection, entityName: "Stock", predicate: predicate, sortDescriptors: sortDescriptors)
            owner?.marketCollection.delegate = self
        }
    }
    
    // Update predicate
    func updatePredicate() {
        // Set new predicate
        let predicate = NSPredicate(format: "mainIndex == false and region == %i", self.owner!.regionControl.selectedSegmentIndex)
        updatePredicate(predicate)
    }
    
    // MARK: - Collection Datasource
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let stock = fetchedResultsController.objectAtIndexPath(indexPath) as! Stock
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("indexCell", forIndexPath: indexPath) as! StockCollectionViewCell
        
        cell.symbolLabel.text = stock.company.name.uppercaseString
        cell.priceLabel.text = stock.price
        cell.changeAvgLabel.text = "\(stock.changeAvg)%"
        cell.changeAvgLabel.textColor = stock.changeAvg > 0 ? ScreenSettings.SFUpColor: ScreenSettings.SFDownColor
        
        return cell
    }
    
    // MARK: - Collection Delegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let stock = fetchedResultsController.objectAtIndexPath(indexPath) as! Stock
        owner!.delegate?.didSelectStock(stock.objectID)
    }
    
}