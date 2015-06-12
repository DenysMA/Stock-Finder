//
//  ShareViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 06/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData
import Social
import MessageUI

class ShareViewController: UIViewController, MFMailComposeViewControllerDelegate, UIAlertViewDelegate {

    internal var newsID: NSManagedObjectID!
    
    // Shared context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presentingViewController?.view.alpha = 0.4
    }
    
    // MARK: - Share resource
    @IBAction func shareResource(sender: UIButton) {
        
        let news = sharedContext.objectWithID(newsID) as! News
        let serviceType: String
        
        switch sender.tag {
        case 0: // Twitter
            serviceType = SLServiceTypeTwitter
            composeForSocialService(serviceType, newsItem: news)
        case 1: // Facebook
            serviceType = SLServiceTypeFacebook
            composeForSocialService(serviceType, newsItem: news)
        case 2: // Mail
            composeMail(news)
        default: return
        }

    }
    
    // MARK: - Compose Message for Social
    func composeForSocialService(serviceType: String, newsItem: News) {
    
        let vc = SLComposeViewController(forServiceType: serviceType)
        vc.completionHandler = { results in
            dispatch_async(dispatch_get_main_queue()) {
                self.dismissShareModal()
            }
        }
        vc.setInitialText(newsItem.title)
        vc.addURL(NSURL(string: newsItem.link))
        if let image = newsItem.newsImage {
            vc.addImage(image)
        }
        presentViewController(vc, animated: true, completion: nil)
    
    }
    
    // MARK: - Compose Mail
    func composeMail(newsItem: News) {
        
        let mailCompose = MFMailComposeViewController()
        mailCompose.mailComposeDelegate = self
        mailCompose.title = newsItem.title
        mailCompose.setSubject(newsItem.title)
        mailCompose.setMessageBody(newsItem.link, isHTML: false)
        presentViewController(mailCompose, animated: true, completion: nil)
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        dismissViewControllerAnimated(true, completion: nil)
        dismissShareModal()
    }
    
    // Dismiss modal
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        dismissShareModal()
    }
    
    // Dismiss modal
    func dismissShareModal() {
        self.presentingViewController?.view.alpha = 1.0
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
