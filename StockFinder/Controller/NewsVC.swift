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
import MediaPlayer

protocol NewsVCDelegate {
    
    func didSelectNews(newsID: NSManagedObjectID)
    func didFinishLoading()
}

class NewsVC: UIViewController {

    @IBOutlet weak var newsTableView: UITableView!
    
    private let newsDS = NewsDS()
    internal var state = State.Initiated
    internal var delegate: NewsVCDelegate?
    internal var error: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set estimated height
        newsTableView.estimatedRowHeight = 180
        newsTableView.rowHeight = UITableViewAutomaticDimension
        newsDS.owner = self
    }
    
    // Table view size
    var size: CGSize {
        get {
            return newsTableView.contentSize
        }
    }
    
    // MARK: - Load content
    func loadNews(symbol: String? = nil) {
        
        newsDS.loadData(symbol: symbol)
    }
    
    // MARK: - Play Video
    @IBAction func playVideo(sender: UIButton) {
        
        let shareButtonPosition = sender.convertPoint(CGPointZero, toView: newsTableView)
        if let news = newsDS.getObjectForPoint(shareButtonPosition) {
            let webVC = storyboard?.instantiateViewControllerWithIdentifier("webView") as! WebViewController
            webVC.link = news.videoURL
            webVC.contentType = ContentType.Video
            presentViewController(webVC, animated: true, completion: nil)
            println(news.videoURL)
        }
    }
    
    // MARK: - Share news
    @IBAction func shareNews(sender: UIButton) {
        
        var news: News?
        let serviceType: String
        let serviceName: String
        let shareButtonPosition = sender.convertPoint(CGPointZero, toView: newsTableView)
        
        if let news = newsDS.getObjectForPoint(shareButtonPosition) {
            
            let shareView = self.storyboard?.instantiateViewControllerWithIdentifier("shareView") as! ShareViewController
            shareView.newsID = news.objectID
            shareView.providesPresentationContextTransitionStyle = true
            shareView.definesPresentationContext = true
            shareView.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            presentViewController(shareView, animated: true, completion: nil)
        }
    }

    // MARK: - More actions
    @IBAction func moreActions(sender: UIButton) {
        
        var news: News?
        let shareButtonPosition = sender.convertPoint(CGPointZero, toView: newsTableView)
        
        if let news = newsDS.getObjectForPoint(shareButtonPosition) {
         
            var items: [AnyObject] = [news.title , NSURL(string: news.link)!]
            if let image = news.newsImage {
                items.append(image)
            }
            let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = sender
            activity.excludedActivityTypes = [UIActivityTypeAssignToContact]
            activity.completionWithItemsHandler = { (activityType, completed, returnItems, activityError ) in
                if completed && activityError == nil {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
            presentViewController(activity, animated: true, completion: nil)
        }
    }
    
}
