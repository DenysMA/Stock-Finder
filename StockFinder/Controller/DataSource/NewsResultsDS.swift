//
//  NewsDS.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 04/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class NewsResultsDS: NSObject, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    private var pendingOperations = PendingOperations()
    private var reuseCell = "newsCell"
    private var emptyDS = EmptyDS()
    private let fetchLimit = 10
    private var fetchOffset = 0
    
    weak var owner: NewsVC? {
        didSet {
            
            // Set data source and delegate
            owner?.newsTableView.dataSource = self
            owner?.newsTableView.delegate = self
            
            // Set reuse cell identifier
            if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
                reuseCell = "shortNewsCell"
            }
            
            // Set up fetchController
            NSFetchedResultsController.deleteCacheWithName("News")
            fetchedResultsController.delegate = self
            fetchedResultsController.performFetch(nil)
        }
    }

    // Shared context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    deinit {
        NSFetchedResultsController.deleteCacheWithName("News")
    }
    
    func loadData() {
        
        // Check news type
        
        let newsType: NewsType
        if let symbol = owner?.newsSymbol {
            newsType = NewsType.CompanyNews
        }
        else {
            // Search Top News
            newsType = NewsType.TopNews
        }
        // Set state
        owner?.state = State.Loading
        YahooClient.sharedInstance().getNews(owner!.newsSymbol) { results, error in
            
            if let error = error {
                
                dispatch_async(dispatch_get_main_queue()){
                    // Set state and error, then notify delegate
                    self.owner?.error = error
                    self.owner?.state = State.Failed
                    self.owner?.delegate?.didFinishLoading()
                }
            }
            else {
                
                if let results = results {
                    dispatch_async(dispatch_get_main_queue()){
                        
                        self.owner?.newsTableView.dataSource = self
                        
                        let guids = results.map() {
                            $0[News.Keys.guid] as! String
                        }
                        let items = self.searchForItems(guids)
                        
                        for dictionary in results {
                            
                            // Check if news already exists
                            let guid = dictionary[News.Keys.guid] as! String
                            let results = items.filter() { $0.guid == guid }
                            if results.isEmpty {
                                // Create news object                                
                                let newsItem = News(dictionary: dictionary, context: self.sharedContext)
                                newsItem.newsType = newsType
                                newsItem.symbol = self.owner!.newsSymbol ?? ""
                            }
                            else {
                                let news = results.first!
                                if news.isContentMainSource && news.source.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty {
                                    YahooClient.sharedInstance().prefetchMediaForNews(news)
                                }
                            }
                        }
                        
                        // Save context and upate status
                        CoreDataStackManager.sharedInstance().saveContext()
                        self.owner?.error = nil
                        self.owner?.state = State.Loaded
                    }
                }
                else {
                    dispatch_async(dispatch_get_main_queue()){
                        self.owner?.newsTableView.dataSource = self.emptyDS
                        self.owner?.newsTableView.delegate = self.emptyDS
                        self.owner?.newsTableView.reloadData()
                        self.owner?.error = nil
                        self.owner?.state = State.Loaded
                        self.owner?.delegate?.didFinishLoading()
                    }
                }
            }
        }
    }
    
    // MARK: - FetchResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create fetch request
        let fetchRequest = NSFetchRequest(entityName: "News")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.includesSubentities = false
        fetchRequest.fetchBatchSize = 10
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.includesPendingChanges = true
        
        // If there is a symbol, search for company news
        if let symbol = self.owner!.newsSymbol {
            fetchRequest.predicate = NSPredicate(format: "symbol == %@", symbol)
        }
        else {
            // Search Top News
            fetchRequest.predicate = NSPredicate(format: "type == %i", NewsType.TopNews.rawValue)
        }
        
        // Create fetchresults controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: "News")
        return fetchedResultsController
        
        }()
    
    func updatePredicateWithSymbol(symbol: String) {
        
        let predicate = NSPredicate(format: "symbol == %@", symbol)
        // Update predicate
        fetchedResultsController.delegate = nil
        sharedContext.reset()
        NSFetchedResultsController.deleteCacheWithName("News")
        fetchedResultsController.fetchRequest.predicate = predicate
        fetchedResultsController.delegate = self
        owner?.newsTableView.reloadData()
        
    }
    
    // MARK: - TableView Datasource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController.sections?.first as? NSFetchedResultsSectionInfo {
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let newsItem = fetchedResultsController.objectAtIndexPath(indexPath) as! News
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseCell, forIndexPath: indexPath) as! NewsTableViewCell
        configureCell(cell, indexPath: indexPath, newsItem: newsItem)
        return cell
    }
    
    // Configure cell
    func configureCell(newsCell: NewsTableViewCell, indexPath: NSIndexPath, newsItem: News) {
        
        // Set placeholder image
        var placeholderImage = UIImage(named: "placeholder")
        newsCell.newsImage.image = placeholderImage
        newsCell.titleLabel.text = newsItem.title
        newsCell.summaryLabel.text = newsItem.summary
        newsCell.sourceLabel.text = (newsItem.source ?? "").uppercaseString
        newsCell.dateLabel.text = Formatter.getStringTimeFromDate(newsItem.date) ?? ""
        newsCell.playButton.hidden = newsItem.videoURL == nil
        
        if let imagePath = newsItem.imageURL {
            
            // Check state of news image
            switch newsItem.state {
                
            case .Failed:
                NSLog("download image failed")
            case .New:
                startDownloadForRecord(indexPath, newsItem: newsItem)
            case .Downloaded:
                if let image = newsItem.newsImage {
                    // Set image
                    newsCell.newsImage.image = image
                    // Set image height constraint
                    if let imageHeight = newsCell.imageHeight {
                        imageHeight.constant = newsCell.newsImage.image!.size.height
                    }
                }
                else {
                    startDownloadForRecord(indexPath, newsItem: newsItem)
                }
                
            default: return
            }
        }
        else if let imageHeight = newsCell.imageHeight {
            imageHeight.constant = 0
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
    }
    
    // MARK: - Start Image Download
    func startDownloadForRecord(indexPath: NSIndexPath, newsItem: News) {
        
        // Check if operation for that index is not in process
        if let downloadOperation = pendingOperations.downloadsInProgress[indexPath] {
            return
        }
        
        // Create Operation Image Downloader
        let downloader = ImageDownloader(newsItem: newsItem)
        
        // Set completion
        downloader.completionBlock = {
            // Check operation status
            if downloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                // Remove operation from downloads array
                self.pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                
                // Reload cell if user is not scrolling
                if let table = self.owner?.newsTableView {
                    if (!table.dragging && !table.decelerating) {
                        self.owner?.newsTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    }
                }
                
            })
        }
        // Add operation to array of downloads and queue
        pendingOperations.downloadsInProgress[indexPath] = downloader
        pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    // MARK: - TableView Delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let news = fetchedResultsController.objectAtIndexPath(indexPath) as! News
        owner?.delegate?.didSelectNews(news.objectID)
    }
    
    // MARK: - FetchResults Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        owner?.newsTableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                owner?.newsTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
                
            case .Delete:
                owner?.newsTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                
            case .Update:
                owner?.newsTableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Move:
                owner?.newsTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                owner?.newsTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            default:
                return
            }
            
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        owner?.newsTableView.endUpdates()
        if owner?.state == .Loaded {
            owner?.delegate?.didFinishLoading()
        }
    }
    
    // MARK: - Object for point
    func getObjectForPoint(position:CGPoint) -> News? {
        
        if let indexPath = owner!.newsTableView.indexPathForRowAtPoint(position) {
            
            return fetchedResultsController.objectAtIndexPath(indexPath) as? News
        }
        return nil
    }
    
    // MARK: - Retrieve news item from persisten store
    func searchForItems(guidArray : [String]) -> [News] {
        
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "News")
        fetchRequest.predicate = NSPredicate(format: "guid in %@", guidArray)
        fetchRequest.includesSubentities = false
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        // Check for Errors
        if error != nil {
            NSLog("Error in fectchWatchList(): \(error)")
        }
        return results as? [News] ?? [News]()
    }
    
}