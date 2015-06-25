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
        refreshControl?.addTarget(self, action: "loadPresentation", forControlEvents: UIControlEvents.ValueChanged)
        refreshControl?.layer.zPosition = tableView.backgroundView!.layer.zPosition + 1
        title = "Company"
        loadCompanyNews()

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.parentViewController!.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - TableView Delegate
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
    }
    
    // MARK: - StockInfoPresentation protocol
    func loadPresentation() {
        refreshControl?.beginRefreshing()
        tableView.contentOffset = CGPointMake(0, tableView.contentOffset.y - refreshControl!.frame.size.height)
        news.updateNewsSymbol(stock.symbol)
    }
    
    func loadCompanyNews() {
        refreshControl?.beginRefreshing()
        tableView.contentOffset = CGPointMake(0, tableView.contentOffset.y - refreshControl!.frame.size.height)
        // Load company news
        news.loadNews()
    }
    
    // MARK: - SearchView Delegate
    
    func didSelectNews(newsID: NSManagedObjectID) {
        performSegueWithIdentifier("showNews", sender: newsID)
    }
    
    func didFinishLoading() {
     
        var newsSize = news.size
        tableView.beginUpdates()
        newsConstraint.constant = newsSize.height
        tableView.endUpdates()
        refreshControl?.endRefreshing()
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
