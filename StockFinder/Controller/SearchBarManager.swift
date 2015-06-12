//
//  SearchBarManager.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 24/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation
import UIKit

class SearchBarManager: NSObject, UIPopoverPresentationControllerDelegate {
    
    var topBar: TopBarViewController!
    var results: SearchViewController!
    var parent: UIViewController!
    
    var title: String? = nil {
        didSet {
            topBar.titleLabel.text = title
        }
    }
    
    // MARK: - Initializer with Delegate
    init(delegate: SearchViewControllerDelegate){
        
        super.init()
        
        // Set parent view controller
        self.parent = delegate as! UIViewController
        
        parent.navigationItem.backBarButtonItem?.title = ""
        
        // Instantiate searchViewController
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        results = storyboard.instantiateViewControllerWithIdentifier("searchResults") as! SearchViewController
        results.delegate = delegate
        
        // Instantiate searBar controller
        topBar = storyboard.instantiateViewControllerWithIdentifier("searchTopBar") as! TopBarViewController
        
        // Get left button size if apply
        let leftBarButtonWidth: CGFloat = parent.navigationItem.leftBarButtonItem?.width ?? 0
        
        // Set searchBar frame
        topBar.view.frame = CGRectMake(0, 0, parent.navigationController!.navigationBar.frame.width - leftBarButtonWidth, parent.navigationController!.navigationBar.frame.height)
        
        parent.navigationItem.titleView = topBar.view
        // Set searchBar delegate
        topBar.searchBar.delegate = results
    }
    
    // MARK: - Popover Config
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController!, traitCollection: UITraitCollection!) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // MARK: - Popover Presentation Controller Delegate
    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {

        topBar.restoreView()
        return true
    }
    
    // MARK: - Show Popover Results
    func showResults() {
        
        // Set presentation style
        results.modalPresentationStyle = UIModalPresentationStyle.Popover
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            results.preferredContentSize = CGSizeMake(topBar.view.frame.width * 0.7, 300)
        }
        else {
            results.preferredContentSize = CGSizeMake(topBar.view.frame.width, 300)
        }
        
        let popover = results.popoverPresentationController
        popover?.sourceView = topBar.searchBar
        popover?.sourceRect = CGRectMake(0, 0, topBar.view.frame.width, topBar.view.frame.height)
        popover?.passthroughViews = [topBar.searchBar]
        popover?.delegate = self
        
        //Present popover
        parent.presentViewController(results, animated: true, completion: nil)
    }
    
    // MARK: - Close Results
    func closeResults() {
        
        parent.dismissViewControllerAnimated(true, completion: nil)
        topBar.restoreView()
    }
}