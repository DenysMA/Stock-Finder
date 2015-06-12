//
//  StockDetailsDS.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 01/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class StockDetailsDS: NSObject, UICollectionViewDataSource {
    
    weak var owner: StockDetailViewController? {
        didSet {
            // Set datasource
            owner?.infoCollection.dataSource = self
        }
    }
    // Get list of fields to display for any stock
    let items = PropertyList.sharedInstance().stockDetailsItems()
    
    // MARK: - Collection DataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let item = items[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("detailCell", forIndexPath: indexPath) as! StockDetailViewCell
        cell.title.text = item["title"]
        cell.value.text = getValue(item)
        
        return cell
    }
    
    // MARK: - Value for Item
    func getValue(item: [String: String]) -> String {
        
        let stock = owner!.stock
        // Values to display
        let fields = item["field"]!.componentsSeparatedByString(",")
        let firstField = fields.first!
        let firstValue = stock.valueForKey(firstField) as! String
        
        // When displaying more than 2 values in a single field, get separator string to format the final value
        if fields.count > 1 {
            let secondField = fields.last!
            let secondValue = stock.valueForKey(secondField) as! String
            let separator = item["separator"] ?? " "
            return "\(firstValue) \(separator) \(secondValue)"
        }
        
        return firstValue
    }
    
}