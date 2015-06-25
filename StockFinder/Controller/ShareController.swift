//
//  ShareViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 06/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import Social
import MessageUI

class ShareController {
    
    // MARK: - Compose Message for Social
    class func composeForSocialServiceInView(serviceType: String, newsItem: News, view: UIViewController) {
    
        let vc = SLComposeViewController(forServiceType: serviceType)
        vc.setInitialText(newsItem.title)
        vc.addURL(NSURL(string: newsItem.link))
        if let image = newsItem.newsImage {
            vc.addImage(image)
        }
        view.presentViewController(vc, animated: true, completion: nil)
    
    }
    
    class func showMoreActionsInView(newsItem: News, view: UIViewController, sourceView: UIView?=nil, item: UIBarButtonItem?=nil) {
        
        var items: [AnyObject] = [newsItem.title , NSURL(string: newsItem.link)!]
        if let image = newsItem.newsImage {
            items.append(image)
        }
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activity.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter]
        activity.completionWithItemsHandler = { (activityType, completed, returnItems, activityError ) in
            if completed && activityError == nil {
                view.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        if let sourceView = sourceView {
            activity.popoverPresentationController?.sourceView = sourceView
        }
        if let item = item {
            activity.popoverPresentationController?.barButtonItem = item
        }
        
        view.presentViewController(activity, animated: true, completion: nil)
    }
    
}
