//
//  SearchViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 14/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

@objc protocol SearchViewControllerDelegate {
    
    func didBeginSearch()
    func didEndEditing()
    func didSelectStock(stockID: NSManagedObjectID)
    optional func didWatchStock()
    optional func didUnWatchStock()
}


class SearchViewController: UITableViewController, UISearchBarDelegate, NSFetchedResultsControllerDelegate {

    private var searchTask: NSURLSessionDataTask?
    private var temporaryContext: NSManagedObjectContext!
    private var stocks = [Stock]()
    private var recentViewed = [Stock]()
    private var emptyDS = EmptyDS()
    private var searchedText = ""
    private var reuseCell = "ticker"
    
    internal var delegate: SearchViewControllerDelegate?
    
    // Shared context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    // MARK: - life Cycle
    override func viewDidLoad() {

        // Set the temporary context
        temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = self.sharedContext.persistentStoreCoordinator
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        // Set cell identifier
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            reuseCell = "shortTicker"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        // Clean up table view content
        searchedText = ""
        stocks = [Stock]()
        recentViewed = fetchWatchList()
        tableView.reloadData()
    }
    
    // Switch data source when there are no results
    func updateDataSource() {
        
        if stocks.count == 0 {
            tableView.dataSource = emptyDS
            tableView.delegate = emptyDS
        }
        else {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    // MARK: - Fetch Watch list
    func fetchWatchList() -> [Stock] {
        
        let error: NSErrorPointer = nil
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Stock")
        fetchRequest.predicate = NSPredicate(format: "region == -1")
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        // Check for Errors
        if error != nil {
            println("Error in fectchWatchList(): \(error)")
        }
        
        // Return the results, cast to an array of Stock objects,
        // or an empty array of Stock objects
        return results as? [Stock] ?? [Stock]()
    }

    // MARK: - Table View Data Source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getCollection().count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let stock =  getCollection()[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseCell, forIndexPath: indexPath) as! StockTableViewCell
        
        cell.symbolLabel.text = stock.symbol
        cell.companyLabel.text = stock.company.name
        
        if let exchangeLabel = cell.exchangeLabel {
            exchangeLabel.text = "\(stock.type) - \(stock.exchange)"
        }
    
        if stock.watched {
            cell.watchButton.setImage(UIImage(named: "watch_on"), forState: UIControlState.Normal)
            cell.watchButton.tag = 1
        }
        else {
            cell.watchButton.setImage(UIImage(named: "watch_off"), forState: UIControlState.Normal)
            cell.watchButton.tag = 0
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if searchedText != "" {
            return 0
        }
        return 30.0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Recent Viewed"
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let stock = getCollection()[indexPath.row]
        let objectID = updateStock(stock)
        delegate?.didEndEditing()
        delegate?.didSelectStock(objectID)
    }
    
    // MARK: - Search Bar Delegate
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        delegate?.didBeginSearch()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        delegate?.didEndEditing()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        searchedText = searchText
        
        // Cancel the last task
        if let task = searchTask {
            task.cancel()
            searchTask = nil
        }
        
        // If the text is empty we are done
        if searchText == "" {
            stocks.removeAll(keepCapacity: false)
            self.tableView!.reloadData()
            return
        }
        
        // Start a new download
        searchTask = YahooFinanceClient.sharedInstance().getSymbolsWithString(searchText) { results, error in
            
            if let error = error {
                println("Error search  \(error)")
            }
            else {
                
                if let results = results {
                    
                    if self.searchTask == nil {
                        return
                    }
                    
                    // Reload the table on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        self.stocks = results.map() { dictionary in
                            
                            let stock = Stock(dictionary: dictionary, context: self.temporaryContext)
                            if let watchedStock = self.getPersistentStock(stock.symbol, watched: true) {
                                stock.watched = true
                            }
                            return stock
                        }
                        
                        self.updateDataSource()
                        self.tableView!.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - Watch Stock
    @IBAction func watchStock(sender: UIButton) {
        
        var stock: Stock?
        let watchButtonPosition = sender.convertPoint(CGPointZero, toView: tableView)
        
        // Get cell indexPath
        if let indexPath = tableView.indexPathForRowAtPoint(watchButtonPosition) {
            stock = getCollection()[indexPath.row]
        }

        // Watch stock
        if sender.tag == 0 {
            sender.tag = 1
            sender.setImage(UIImage(named: "watch_on"), forState: UIControlState.Normal)
            
            if let stock = stock {
                stock.watched = true
                updateStock(stock)
                delegate?.didWatchStock!()
            }
        }
        else {
            // Unwatch stock
            sender.tag = 0
            sender.setImage(UIImage(named: "watch_off"), forState: UIControlState.Normal)
            
            if let stock = stock {
                stock.watched = false
                updateStock(stock)
                delegate?.didUnWatchStock!()
            }
        }
    }
    
    // MARK: - Update stock
    func updateStock(stock: Stock) -> NSManagedObjectID {
        
        if let persistenStock = getPersistentStock(stock.symbol) {
            persistenStock.mergeValues([Stock.Keys.watched: stock.watched])
            return persistenStock.objectID
        }
        else {

            let dictionary: [String: AnyObject] = [
                Stock.Keys.symbol: stock.symbol,
                Stock.Keys.type: stock.type,
                Stock.Keys.exchange: stock.exchange,
                Stock.Keys.watched: stock.watched,
                Company.Keys.name: stock.company.name]
            
            let stock = Stock(dictionary: dictionary, context: sharedContext)
            recentViewed.append(stock)
            sharedContext.obtainPermanentIDsForObjects([stock], error: nil)
            return stock.objectID
        }
    }

    // Look if a stock is already persisted
    func getPersistentStock(symbol: String, watched: Bool? = nil) -> Stock? {
        
        let result = self.recentViewed.filter() {
            if let watched = watched {
                return symbol == $0.symbol && $0.watched
            }
            return symbol == $0.symbol
        }
        return result.first
    }
    
    // MARK: - Get current collection (Search Results or Recent Viewed)
    func getCollection() -> [Stock] {
        
        if searchedText != "" {
            return stocks
        }
        return recentViewed
    }
    
}
