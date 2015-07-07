//
//  NewsVC.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 05/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import Social
import CoreData

protocol NewsVCDelegate: class {
    
    func didSelectNews(newsID: NSManagedObjectID)
    func didFinishLoading()
}

class NewsVC: UIViewController {

    @IBOutlet weak var newsTableView: UITableView!
    private let newsDS = NewsDS()
    internal var state = State.Initiated
    internal weak var delegate: NewsVCDelegate?
    internal var newsSymbol: String?
    internal var error: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set estimated height
        newsTableView.estimatedRowHeight = 180
        newsTableView.rowHeight = UITableViewAutomaticDimension
        newsDS.owner = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        newsDS.reloadContent()
    }
    
    // Table view size
    var size: CGSize {
        get {
            newsTableView.layoutIfNeeded()
            return newsTableView.contentSize
        }
    }
    
    deinit {
        error = nil
        delegate = nil
    }
    
    // MARK: - Load content
    func loadNews() {
        newsDS.loadData()
    }
    
    func updateNewsSymbol(symbol: String) {
        newsSymbol = symbol
        newsDS.updatePredicate()
    }
    
    // MARK: - Play Video
    @IBAction func playVideo(sender: UIButton) {
        
        let shareButtonPosition = sender.convertPoint(CGPointZero, toView: newsTableView)
        if let news = newsDS.getObjectForPoint(shareButtonPosition) {
            let webVC = storyboard?.instantiateViewControllerWithIdentifier("webView") as! WebViewController
            webVC.link = news.videoURL
            webVC.contentType = ContentType.Video
            presentViewController(webVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Share facebook
    @IBAction func shareWithFacebook(sender: UIButton) {
        
        let serviceType = SLServiceTypeFacebook
        let shareButtonPosition = sender.convertPoint(CGPointZero, toView: newsTableView)
        
        if let news = newsDS.getObjectForPoint(shareButtonPosition) {
            ShareController.composeForSocialServiceInView(serviceType, newsItem: news, view: self)
        }
    }
    
    // MARK: - Share twitter
    @IBAction func shareWithTwitter(sender: UIButton) {
        
        let serviceType = SLServiceTypeTwitter
        let shareButtonPosition = sender.convertPoint(CGPointZero, toView: newsTableView)
        
        if let news = newsDS.getObjectForPoint(shareButtonPosition) {
            ShareController.composeForSocialServiceInView(serviceType, newsItem: news, view: self)
        }
    }

    // MARK: - More actions
    @IBAction func moreActions(sender: UIButton) {
        
        let shareButtonPosition = sender.convertPoint(CGPointZero, toView: newsTableView)
        
        if let news = newsDS.getObjectForPoint(shareButtonPosition) {
            ShareController.showMoreActionsInView(news, view: self, sourceView: sender)
            
        }
    }
    
}
