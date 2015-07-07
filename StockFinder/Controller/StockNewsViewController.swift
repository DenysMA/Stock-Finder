//
//  StockNewsViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 21/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class StockNewsViewController: UITableViewController, StockInfoPresentation, NewsVCDelegate {

    @IBOutlet weak var newsConstraint: NSLayoutConstraint!
    private var news: NewsVC!
    internal var stock: Stock!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set estimated height
        tableView.estimatedRowHeight = 152.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Set tableView background
        let background = UIImageView(image: UIImage(named: "background"))
        background.frame = tableView.bounds
        tableView.backgroundView = background
        
        // Set up refresh control
        let customRefreshControl = CustomRefreshControl()
        customRefreshControl.topContentInset = 0
        customRefreshControl.topContentInsetSaved = true
        refreshControl = customRefreshControl
        refreshControl?.addTarget(self, action: "loadCompanyNews", forControlEvents: UIControlEvents.ValueChanged)
        refreshControl?.layer.zPosition = tableView.backgroundView!.layer.zPosition + 1
        
        title = "News"
        loadCompanyNews()

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIView.setAnimationsEnabled(true)
        self.parentViewController!.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - TableView Delegate
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
    }
    
    // MARK: - StockInfoPresentation protocol
    func loadPresentation() {
        UIView.setAnimationsEnabled(true)
        refreshControl?.beginRefreshing()
        tableView.contentOffset = CGPointMake(0, -refreshControl!.frame.size.height)
        news.updateNewsSymbol(stock.symbol)
    }
    
    func loadCompanyNews() {
        UIView.setAnimationsEnabled(true)
        refreshControl?.beginRefreshing()
        tableView.contentOffset = CGPointMake(0, -refreshControl!.frame.size.height)
        // Load company news
        news.loadNews()
    }
    
    // MARK: - SearchView Delegate
    
    func didSelectNews(newsID: NSManagedObjectID) {
        performSegueWithIdentifier("showNews", sender: newsID)
    }
    
    func didFinishLoading() {
     
        var contentOffset = tableView.contentOffset
        var newsSize = news.size
        
        if refreshControl!.refreshing {
            refreshControl?.endRefreshing()
        }
        else {
            UIView.setAnimationsEnabled(false)
        }
        
        tableView.beginUpdates()
        newsConstraint.constant = newsSize.height
        tableView.endUpdates()
        
        tableView.setContentOffset(contentOffset, animated: false)
        
        if news.size != newsSize {
            didFinishLoading()
        }
    }
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            switch identifier {
                
            case "news":
                news = segue.destinationViewController as! NewsVC
                news.newsSymbol = stock.symbol
                news.delegate = self
            case "showNews":
                self.parentViewController!.navigationController?.setNavigationBarHidden(true, animated: true)
                let newsDisplay = segue.destinationViewController as! NewsDisplayVC
                newsDisplay.newsID = sender as! NSManagedObjectID
            default: return
                
            }
        }
    }
    

}
