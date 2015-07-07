//
//  DashboardVC.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 04/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

enum State { case Initiated, Loading, Loaded, Failed, Cancelled }

class DashboardVC: UITableViewController, UISearchBarDelegate, UIScrollViewDelegate, MarketVCDelegate, NewsVCDelegate, WatchListDelegate, SearchViewControllerDelegate {

    @IBOutlet weak var headerView: UIView!
    private var marketOverview: MarketOverviewVC!
    private var watchList: WatchSearchListVC!
    private var news: NewsVC!
    private var searchManager: SearchBarManager!
    private var headerHeight: CGFloat = 0
    
    //Constraints
    @IBOutlet weak var watchListHeight: NSLayoutConstraint!
    @IBOutlet weak var newsHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set estimated height
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        headerHeight = ScreenSettings.sizeForOrientation(UIInterfaceOrientation.Portrait).height / 3
        
        // Add background table
        let background = UIImageView(image: UIImage(named: "background"))
        background.frame = tableView.bounds
        tableView.backgroundView = background
        
        // Instantiate market summary view controller
        marketOverview = storyboard?.instantiateViewControllerWithIdentifier("marketSummary") as! MarketOverviewVC
        marketOverview.delegate = self
        headerView = marketOverview.view
        
        // Create search bar
        searchManager = SearchBarManager(delegate: self)
        searchManager.title = "STOCK FINDER"
        
        // Set up table header
        configureHeader()
        
        // Set up refresh control
        let customRefreshControl = CustomRefreshControl()
        customRefreshControl.topContentInset = headerHeight
        customRefreshControl.topContentInsetSaved = true
        refreshControl = customRefreshControl
        refreshControl?.addTarget(self, action: "loadContent", forControlEvents: UIControlEvents.ValueChanged)
        refreshControl?.layer.zPosition = headerView.layer.zPosition + 1
        
        loadContent()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        didBeginLoading()
        marketOverview.loadMarketInfo()
        watchList.loadStockInfo()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderView()
    }
    
    // MARK: - Load view controller content
    
    func loadContent() {
    
        didBeginLoading()
        marketOverview.loadMarketInfo()
        watchList.loadStockInfo()
        news.loadNews()
    }
    
    // Update background cell
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        UIView.setAnimationsEnabled(true)
        cell.backgroundColor = UIColor.clearColor()
    }
    
    // MARK: - Delegate methods
    
    func didSelectNews(newsID: NSManagedObjectID) {
        UIView.setAnimationsEnabled(true)
        performSegueWithIdentifier("showNews", sender: newsID)
    }
    
    func didFinishLoading() {
        
        if watchList.state != .Loading && news.state != .Loading && marketOverview.state != .Loading {
        
            var newsSize = news.size
            handleErrors()
            
            if refreshControl!.refreshing {
                refreshControl?.endRefreshing()
                tableView.contentOffset = CGPointMake(0, -headerHeight)
            }
            else {
                UIView.setAnimationsEnabled(false)
            }
            tableView.beginUpdates()
            watchListHeight.constant = watchList.size.height
            newsHeight.constant = newsSize.height
            tableView.endUpdates()
            
            if news.size != newsSize {
                didFinishLoading()
            }
        }
    }
    
    func didTapOnSearchSuggestion() {
        searchManager.search()
    }
    
    func didBeginLoading() {
        
        UIView.setAnimationsEnabled(true)
        if tableView.contentOffset.y >= -headerHeight - refreshControl!.frame.size.height && tableView.contentOffset.y < 0 {
            tableView.contentOffset = CGPointMake(0, -headerHeight - refreshControl!.frame.size.height)
            refreshControl?.beginRefreshing()
        }
    }
    
    func handleErrors() {
        
        var errorSet: Set<String> = Set()
        
        if let error = watchList.error {
            errorSet.insert(error)
            watchList.error = nil
        }
        if let error = news.error {
            errorSet.insert(error)
            news.error = nil
        }
        if let error = marketOverview.error {
            errorSet.insert(error)
            marketOverview.error = nil
        }
        if !errorSet.isEmpty {
            let messages = ".".join(errorSet)
            let message = UIAlertView(title: "An Error Ocurred", message: messages, delegate: nil, cancelButtonTitle: "OK")
            message.show()
        }
    }

    // MARK: - SearchViewController Delegate
    
    func didBeginSearch() {
        
        searchManager.showResults()
    }
    
    func didEndEditing() {
        
        searchManager.closeResults()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func didSelectStock(stockID: NSManagedObjectID) {
        
        performSegueWithIdentifier("stockInfo", sender: stockID)
    }
    
    func didWatchStock() {
        
        searchManager.closeResults()
        CoreDataStackManager.sharedInstance().saveContext()
        tableView.beginUpdates()
        tableView.endUpdates()
        watchList.loadStockInfo()
    }
    
    func didUnWatchStock() {
        
        searchManager.closeResults()
        CoreDataStackManager.sharedInstance().saveContext()
        tableView.beginUpdates()
        tableView.endUpdates()
        watchList.loadStockInfo()
    }
    
    // MARK: - Header configuration
    
    func configureHeader() {
        
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -headerHeight)
        updateHeaderView()
    }
    
    func updateHeaderView() {
        
        let origin = tableView.center.x - tableView.bounds.width / 2
        var headerRect = CGRect(x: origin, y: -headerHeight, width: tableView.bounds.width, height: headerHeight)
        if tableView.contentOffset.y < -headerHeight {
            headerRect.origin.y = tableView.contentOffset.y
            headerRect.size.height = -tableView.contentOffset.y
        }
        headerView.frame = headerRect

    }
    
    // MARK: - Scroll Delegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        updateHeaderView()
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            switch identifier {
                
            case "marketOverview":
                marketOverview = segue.destinationViewController as! MarketOverviewVC
                marketOverview.delegate = self
            case "watchList":
                watchList = segue.destinationViewController as! WatchSearchListVC
                watchList.delegate = self
            case "news":
                news = segue.destinationViewController as! NewsVC
                news.delegate = self
            case "showNews":
                let newsDisplay = segue.destinationViewController as! NewsDisplayVC
                newsDisplay.newsID = sender as! NSManagedObjectID
            case "stockInfo":
                let stockInfo = segue.destinationViewController as! StockInfoViewController
                stockInfo.stockID = sender as! NSManagedObjectID
            default: return
                
            }
        }
        
    }
    
}
