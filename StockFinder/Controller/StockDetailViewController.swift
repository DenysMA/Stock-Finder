//
//  StockDetailViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 21/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class StockDetailViewController: UITableViewController, StockInfoPresentation {

    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var exchangeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var indicatorImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var changeAvgLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateAHLabel: UILabel!
    @IBOutlet weak var priceAHLabel: UILabel!
    @IBOutlet weak var changeAHLabel: UILabel!
    @IBOutlet weak var changeAvgAHLabel: UILabel!
    @IBOutlet weak var afterHoursView: UIView!
    @IBOutlet weak var graphImage: UIImageView!
    @IBOutlet weak var infoCollection: UICollectionView!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var collectionConstraint: NSLayoutConstraint!
    
    internal var stock: Stock!
    private var searchTask: NSURLSessionDataTask?
    private let infoCollectionDS = StockDetailsDS()
    
    // Shared context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set estimated height
        tableView.estimatedRowHeight = 300.0
        tableView.rowHeight = UITableViewAutomaticDimension
        // Set up datasource
        infoCollectionDS.owner = self
        // Download chart image
        downloadImage()
        
        // Set up refresh control
        refreshControl = UIRefreshControl(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height * 0.01))
        refreshControl?.addTarget(self, action: "loadPresentation", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load content
        loadStock()
        downloadStockInfo()
        infoCollection.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate collection item size
        let flowLayout = infoCollection.collectionViewLayout as! UICollectionViewFlowLayout
        
        let minimumWidth: CGFloat = 320.0
        var preferedWidth = UIScreen.mainScreen().bounds.width * 0.48
        
        if preferedWidth < minimumWidth {
            preferedWidth = UIScreen.mainScreen().bounds.width
        }
        flowLayout.itemSize = CGSize(width: preferedWidth, height: 50)
        collectionConstraint.constant = flowLayout.collectionViewContentSize().height
        flowLayout.invalidateLayout()
    }

    // MARK: - Update chart timespan
    @IBAction func changeTimeSpan(sender: UISegmentedControl) {
        
        let selectedIndex = sender.selectedSegmentIndex
        let timeSpan = sender.titleForSegmentAtIndex(selectedIndex)!.lowercaseString
        
        YahooClient.sharedInstance().getChartData(stock.symbol, timeSpan: timeSpan) { data, error in
            
            if let error = error {
            }
            else if let data = data {
                dispatch_async(dispatch_get_main_queue()) {
                    self.graphImage.image = UIImage(data: data)
                }
            }
        }
    }
    
    // MARK: - Watch/Unwatch Stock
    @IBAction func watchStock(sender: UIButton) {
        
        stock.mergeValues([Stock.Keys.watched : !stock.watched])
        CoreDataStackManager.sharedInstance().saveContext()
        setWatchButton()
    }
    
    // MARK: - Set View Content
    func loadStock() {
        
        symbolLabel.text = stock.symbol.uppercaseString
        exchangeLabel.text = "\(stock.type) - \(stock.exchange)".uppercaseString
        priceLabel.text = stock.price
        
        if stock.change > 0 {
            changeLabel.text = "+\(stock.change)"
            changeLabel.textColor = ScreenSettings.SFUpColor
            indicatorImage.image = UIImage(named: "arrow_up")
        }
        else {
            changeLabel.text = "\(stock.change)"
            changeLabel.textColor = ScreenSettings.SFDownColor
            indicatorImage.image = UIImage(named: "arrow_down")
        }
        changeAvgLabel.text = "(\(stock.changeAvg))%"
        changeAvgLabel.textColor = changeLabel.textColor
        dateLabel.text = stock.stockDate
        if stock.dateAH == "NA" {
            afterHoursView.hidden = true
        }
        else {
            afterHoursView.hidden = false
            dateAHLabel.text = stock.dateAH
            priceAHLabel.text = stock.priceAH
            changeAHLabel.text = stock.changeAH
            changeAvgAHLabel.text = stock.changeAvgAH
        }
        
        setWatchButton()
        infoCollection.reloadData()
        refreshControl?.endRefreshing()
    }
    
    // Set up watch button
    func setWatchButton() {
        let imageName = stock.watched ? "watch_on" : "watch_off"
        let buttonTitle = stock.watched ? "Unwatch" : "Watch"
        watchButton.setImage(UIImage(named: imageName), forState: UIControlState.Normal)
        watchButton.setTitle(buttonTitle, forState: UIControlState.Normal)
    }
    
    // MARK: - Donwload content
    func downloadStockInfo() {
        
        // Cancel the last task
        if let task = searchTask {
            task.cancel()
            searchTask = nil
        }
        
        // Start a new one download
        searchTask = YahooClient.sharedInstance().getQuoteDetails(stock.symbol) { result, error in
            
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    let message = UIAlertView(title: "An Error Ocurred", message: error, delegate: nil, cancelButtonTitle: "OK")
                    message.show()
                }
            }
            else if let result = result {
                
                self.stock.mergeValues(result)
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.loadStock()
                    if self.stock.watched {
                        self.stock.managedObjectContext?.save(nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Download chart Image
    func downloadImage() {
        
        activityIndicator.startAnimating()
        YahooClient.sharedInstance().getChartData(stock.symbol, timeSpan: "1d") { data, error in
            
            if let error = error {
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.graphImage.image = UIImage(named: "chart")
                }
            }
            else if let data = data {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.graphImage.image = UIImage(data: data)
                }
            }
        }
    }
    
    // MARK: - StockInfoPresentation Protocol
    func loadPresentation() {
        
        loadStock()
        downloadStockInfo()
        downloadImage()
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.parentViewController!.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    

}
