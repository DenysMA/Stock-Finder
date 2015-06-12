//
//  EmptyDS.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 28/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit

class EmptyDS: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Empty Data Source Methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 // default row
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // return empty cell configured in table view in the story board
        return tableView.dequeueReusableCellWithIdentifier("empty", forIndexPath: indexPath) as! UITableViewCell
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Set height full screen
        return tableView.frame.height
    }
    
}
