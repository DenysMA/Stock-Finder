//
//  WebViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 01/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import WebKit

enum ContentType {
    case Video, WebPage
}

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
   

    @IBOutlet weak var contentViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var webContentView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var webView: WKWebView!
    internal var link: String!
    internal var contentType: ContentType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If content is not a video, resize content view to full screen
        if contentType != .Video {
            contentViewConstraint.constant = 0
        }
        else {
            // If video hide navigation controls
            backButton.hidden = true
            urlLabel.hidden = true
        }
        
        // Create Web view
        var webViewConfig: WKWebViewConfiguration = WKWebViewConfiguration()
        var controller = WKUserContentController()
        webViewConfig.userContentController = controller
  
        webView = WKWebView(frame: webContentView.bounds, configuration: webViewConfig)
        webView.navigationDelegate = self
        
        // Set delegate
        webView.UIDelegate = self
        webView.opaque = false
        webView.backgroundColor = UIColor.blackColor()
        webContentView.addSubview(webView)
        webContentView.sendSubviewToBack(webView)
        
        urlLabel.text = link
        
        // Load page
        loadPage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = webContentView.bounds
    }
    
    // MARK: - Load web content
    func loadPage(){
        
        let url = NSURL(string: link.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
    }

    // MARK: - Dismiss Web View
    @IBAction func closeView(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Back
    @IBAction func back(sender: UIButton) {
        webView.goBack()
    }
    
    // MARK: - WKNavigationDelegate
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        activityIndicator.startAnimating()
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        activityIndicator.stopAnimating()
        view.layoutIfNeeded()
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        let message = UIAlertView(title: "An Error Ocurred", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
        message.show()
        activityIndicator.stopAnimating()
    }
    
    // MARK: - Supported interface orientation
    override func supportedInterfaceOrientations() -> Int {
        if contentType == .Video {
            return Int(UIInterfaceOrientationMask.Landscape.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

}
