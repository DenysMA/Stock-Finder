//
//  NewsDisplayVC.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 06/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import QuartzCore
import CoreData
import WebKit
import Social

class NewsDisplayVC: UITableViewController, WKNavigationDelegate, UIScrollViewDelegate {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var creditsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var webContentView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //Constraints
    @IBOutlet weak var webContentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var webContentViewWidth: NSLayoutConstraint!
    @IBOutlet weak var headerWidth: NSLayoutConstraint!
    
    private var news: News!
    private var webView: WKWebView!
    private var moreButton: UIBarButtonItem!
    internal var newsID: NSManagedObjectID!

    // Shared context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get news object
        self.news = sharedContext.objectWithID(self.newsID) as! News
        
        // Set constraints
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            
            headerWidth.constant = ScreenSettings.sizeForOrientation(UIInterfaceOrientation.Portrait).width
            webContentViewWidth.constant = headerWidth.constant - 30
        }
        
        // Set estimated height
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
        configureHeader()
        configureWebContent()
        webContentView.addSubview(webView)
        navigationItem.backBarButtonItem?.title = ""
        
        // Configure share buttons
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: "")
        space.width = -10
        let facebook = UIBarButtonItem(image: UIImage(named: "facebookBar"), style: .Plain, target: self, action: "shareWithFacebook")
        let twitter = UIBarButtonItem(image: UIImage(named: "twitterBar"), style: .Plain, target: self, action: "shareWithTwitter")
        moreButton = UIBarButtonItem(image: UIImage(named: "moreBar"), style: .Plain, target: self, action: "moreActions")
        navigationItem.rightBarButtonItems = [moreButton, twitter, facebook]
        
        // Load content
        loadNewsInfo()
        
        if news.newsContent == nil && news.isContentMainSource {
            downloadNewsContent()
        }
        else if !news.isContentMainSource {
            loadDescription()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update constraints
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            headerWidth.constant = UIScreen.mainScreen().bounds.width
            webContentViewWidth.constant = headerWidth.constant - 30
        }
        
        webView.frame = webContentView.bounds
        updateHeaderView()
    }
    
    deinit {
        NSLog("Deinit")
    }

    // MARK: - Load content
    func loadNewsInfo(){

        setNewsImage()
        titleLabel.text = news.title
        creditsLabel.text = news.credits
        sourceLabel.text = news.source.uppercaseString
        dateLabel.text = Formatter.getStringTimeFromDate(news.date)
        
        if let content = news.newsContent?.htmlContent {
            var html = NSString(data:  content, encoding: NSUTF8StringEncoding) as! String
            let header = "<header><meta name=\"viewport\" content=\"initial-scale=1, user-scalable=no\"></meta><style>body {background-color:black; font-family:\"HelveticaNeue-Light\"; font-size:\(ScreenSettings.SFPreferedFontSize)px; color:white } a {color: #007AFF;}</style></header>"
            
            html = html.stringByReplacingOccurrencesOfString("<header/>", withString: header, options: NSStringCompareOptions.allZeros, range: nil)
            webView.loadHTMLString(html, baseURL:  NSURL(string: news.link))
        }
    }
    
    // MARK: - Load news description
    func loadDescription() {
     
        self.descriptionLabel.text = self.news.summary
        self.tableView.beginUpdates()
        self.webContentView.removeFromSuperview()
        self.tableView.endUpdates()
    }
    
    // MARK: - Download news content
    func downloadNewsContent() {
        
        activityIndicator.startAnimating()
        YahooClient.sharedInstance().getNewsContent(news.link) { results, error in
            
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    let message = UIAlertView(title: "Download error", message: error, delegate: nil, cancelButtonTitle: "OK")
                    self.activityIndicator.stopAnimating()
                    message.show()
                }
            }
            else {
                
                if let results = results {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        self.activityIndicator.stopAnimating()
                        if let content = results[Content.Keys.content] as? NSData {
                            
                            let newContent = Content(dictionary: results, context: self.sharedContext)
                            self.news.newsContent = newContent
                            CoreDataStackManager.sharedInstance().saveContext()
                            self.loadNewsInfo()
                        }
                        else {
                            self.loadDescription()
                        }
                    }
                }
                else {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        self.loadDescription()
                    }
                }
            }
        }
    }
    
    // MARK: - Set image
    func setNewsImage() {
        
        if let imageURL = news.imageURL {
            switch news.state {
            case .Downloaded: self.imageView.image = news.newsImage
            default:
                let downloader = ImageDownloader(newsItem: news)
                downloader.completionBlock = {
                    dispatch_async(dispatch_get_main_queue()) {
                        if self.news.newsImage != nil {
                            self.imageView.image = self.news.newsImage
                        } else {
                            self.imageView.image = UIImage(named: "news")
                        }
                    }
                }
                downloader.start()
            }
        }
        else {
            self.imageView.image = UIImage(named: "news")
        }
        
        playButton.hidden = news.videoURL == nil
    }
    
    // MARK: - Web View Delegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    
        configureWebViewContent()
        let times = 1
        for times in 1...5 {
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                if self.webContentViewHeight.constant != 0 || self.webContentViewHeight.constant < self.webView.scrollView.contentSize.height {
                    self.configureWebViewContent()
                }
            }
        }
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        let message = UIAlertView(title: "An Error Ocurred", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
        message.show()
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if navigationAction.navigationType == .LinkActivated {
            decisionHandler(WKNavigationActionPolicy.Cancel)
            if let stringURL = navigationAction.request.URL?.absoluteString {
                let webVC = storyboard?.instantiateViewControllerWithIdentifier("webView") as! WebViewController
                webVC.link = stringURL
                webVC.contentType = ContentType.WebPage
                presentViewController(webVC, animated: true, completion: nil)
            }
        }
        else {
            decisionHandler(WKNavigationActionPolicy.Allow)
        }
    }
    
    // Update web content view height
    func configureWebViewContent(){
    
        tableView.reloadData()
        tableView.beginUpdates()
        webContentViewHeight.constant = webView.scrollView.contentSize.height
        tableView.endUpdates()
    }

    // MARK: - Set up strechy header
    func configureHeader() {
        
        let headerHeight: CGFloat = headerWidth.constant / 2
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -headerHeight)
        updateHeaderView()
    }
    
    func updateHeaderView() {
        
        let headerHeight: CGFloat = headerWidth.constant / 2
        let origin = tableView.center.x - headerWidth.constant / 2
        var headerRect = CGRect(x: origin, y: -headerHeight, width: headerWidth.constant, height: headerHeight)
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
    
    // MARK: - Share facebook
    func shareWithFacebook() {
        
        let serviceType = SLServiceTypeFacebook
        ShareController.composeForSocialServiceInView(serviceType, newsItem: news, view: self)
    }
    
    // MARK: - Share twitter
    func shareWithTwitter() {
        
        let serviceType = SLServiceTypeTwitter
        ShareController.composeForSocialServiceInView(serviceType, newsItem: news, view: self)
    }
    
    // MARK: - More actions
    func moreActions() {
        ShareController.showMoreActionsInView(news, view: self, item: moreButton)
    }
    
    // Configure webView properties
    func configureWebContent() {
    
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.opaque = false
        webView.scrollView.scrollEnabled = false
        webView.scrollView.bounces = false
    }
    
    // MARK: - Play video
    @IBAction func playVideo(sender: AnyObject) {
        
        let webVC = storyboard?.instantiateViewControllerWithIdentifier("webView") as! WebViewController
        webVC.link = news.videoURL
        webVC.contentType = ContentType.Video
        presentViewController(webVC, animated: true, completion: nil)
    }
    
    // MARK: - Open Article in WebView
    @IBAction func viewFullArticle(sender: AnyObject) {
        
        let webVC = storyboard?.instantiateViewControllerWithIdentifier("webView") as! WebViewController
        webVC.link = news.link
        webVC.contentType = ContentType.WebPage
        presentViewController(webVC, animated: true, completion: nil)
        
    }
}
