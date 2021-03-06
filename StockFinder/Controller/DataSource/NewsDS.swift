//
//  NewsDS1.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 27/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class NewsDS: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    private var pendingOperations = PendingOperations()
    private var temporaryContext: NSManagedObjectContext!
    private var reuseCell = "newsCell"
    private var emptyDS = EmptyDS()
    private var offset = 0
    private var limit = 10
    private var totalObjects = 0
    private var news = [News]()
    private var moreButton: UIButton!
    private var downloaded = false
    
    weak var owner: NewsVC? {
        didSet {
            
            // Set data source and delegate
            owner?.newsTableView.dataSource = self
            owner?.newsTableView.delegate = self
            
            // Set reuse cell identifier
            if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
                reuseCell = "shortNewsCell"
            }
            
            // Set the temporary context
            temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            temporaryContext.persistentStoreCoordinator = self.sharedContext.persistentStoreCoordinator
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "didFinishSaving:", name: NSManagedObjectContextDidSaveNotification, object: temporaryContext)
            
            moreButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
            moreButton.frame = CGRectMake(0, 0, owner!.newsTableView.frame.width, 44)
            moreButton.backgroundColor = UIColor.blackColor()
            moreButton.setTitle("More News", forState: UIControlState.Normal)
            moreButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            moreButton.addTarget(self, action: "loadMore", forControlEvents: UIControlEvents.TouchUpInside)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        temporaryContext.reset()
        sharedContext.reset()
    }
    
    // Shared context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
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
        downloaded = false
        offset = 0
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
                        self.owner?.newsTableView.delegate = self
                        
                        let guids = results.map() {
                            $0[News.Keys.guid] as! String
                        }
                        let items = self.searchForItems(guids)
                        
                        for dictionary in results {
                            
                            // Check if news already exists
                            let guid = dictionary[News.Keys.guid] as! String
                            let results = items.filter() { $0.guid == guid }
                            if results.isEmpty {
                                // Create news objec 
                                let newsItem = News(dictionary: dictionary, context: self.temporaryContext)
                                newsItem.newsType = newsType
                                newsItem.symbol = self.owner!.newsSymbol ?? ""
                            }
                            else {
                                let news = results.first!
                                if news.isContentMainSource && news.imageURL == nil && news.state == .Failed {
                                    YahooClient.sharedInstance().prefetchMediaForNews(news)
                                }
                            }
                        }
                        
                        // Save context and upate status
                        self.downloaded = true
                        self.owner?.error = nil
                        if self.temporaryContext.hasChanges {
                            self.temporaryContext.save(nil)
                        }
                        else {
                            self.refreshContent()
                        }
            
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
    
    // MARK: - Fetch News
    func fetchNews() -> [News] {
        
        let error: NSErrorPointer = nil
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "News")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.includesSubentities = false
        fetchRequest.includesPendingChanges = false
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = offset
        
        // If there is a symbol, search for company news
        if let symbol = self.owner!.newsSymbol {
            fetchRequest.predicate = NSPredicate(format: "symbol == %@", symbol)
        }
        else {
            // Search Top News
            fetchRequest.predicate = NSPredicate(format: "type == %i", NewsType.TopNews.rawValue)
        }

        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        if offset == 0 {
            fetchRequest.fetchLimit = 0
            totalObjects = sharedContext.countForFetchRequest(fetchRequest, error: nil)
        }
        
        // Check for Errors
        if error != nil {
            NSLog("Error in fectchWatchList(): \(error)")
        }
        
        // Return the results, cast to an array of Stock objects,
        // or an empty array of Stock objects
        return results as? [News] ?? [News]()
    }

    func reloadContent() {
        offset = 0
        limit = news.count
        news = self.fetchNews()
        owner?.newsTableView.reloadData()
        limit = 10
    }
    
    func loadMore() {

        offset = offset + limit
        for item in fetchNews() {
            news.append(item)
        }
        refreshContent()
    }
    
    func updatePredicate() {
        
        offset = 0
        news.removeAll(keepCapacity: true)
        owner?.newsTableView.reloadData()
        sharedContext.reset()
        loadData()
        
    }
    
    func didFinishSaving(notification: NSNotification) {
        sharedContext.mergeChangesFromContextDidSaveNotification(notification)
        refreshContent()
    }
    
    func refreshContent() {
        if downloaded {
            
            var itemsWithoutMedia = [News]()
            if offset == 0 {
                self.news = self.fetchNews()
                itemsWithoutMedia = news.filter() {
                    !$0.isMediaDownloaded
                }
            }
            
            if itemsWithoutMedia.isEmpty {
                owner?.newsTableView.reloadData()
                owner?.state = .Loaded
                owner?.delegate?.didFinishLoading()
            }
        }
    }
    
    // MARK: - TableView Datasource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return news.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let newsItem = news[indexPath.row]
        var newsCell: NewsTableViewCell? = nil
        if let cell = tableView.dequeueReusableCellWithIdentifier(reuseCell) as? NewsTableViewCell {
            newsCell = cell
        }
        else {
            newsCell = NewsTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: reuseCell)
        }
        configureCell(newsCell!, indexPath: indexPath, newsItem: newsItem)
        return newsCell!
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
                if let imageHeight = newsCell.imageHeight {
                    imageHeight.constant = 0
                }
            case .New:
                startDownloadForRecord(indexPath, newsItem: newsItem)
            case .Downloaded:
                if let image = newsItem.newsImage {
                    // Set image
                    newsCell.newsImage.image = image
                    // Set image height constraint
                    if let imageHeight = newsCell.imageHeight {
                        imageHeight.constant = newsCell.newsImage.frame.width/2
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
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if downloaded && news.count > 0 && news.count < totalObjects - 1 {
            return 44.0
        }
        return 0
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return moreButton
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
        
        let newsItem = news[indexPath.row]
        owner?.delegate?.didSelectNews(newsItem.objectID)
    }
    
    // MARK: - Object for point
    func getObjectForPoint(position:CGPoint) -> News? {
        
        if let indexPath = owner!.newsTableView.indexPathForRowAtPoint(position) {
            
            return news[indexPath.row]
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