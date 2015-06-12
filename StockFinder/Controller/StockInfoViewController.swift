//
//  StockInfoViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 21/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class StockInfoViewController: UITabBarController, UITabBarControllerDelegate, SearchViewControllerDelegate {

    internal var stockID: NSManagedObjectID!
    private var searchManager: SearchBarManager!
    private var stockViewControllers: [UIViewController]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set tabbar appearance
        UITabBar.appearance().tintColor = UIColor.whiteColor()
        stockViewControllers = self.viewControllers as! [UIViewController]
        
        // Set up search bar
        searchManager = SearchBarManager(delegate: self)
        
        // Set Up View controllers
        setUpViewControllers()
    }
    
    func setUpViewControllers() {
        
        var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
        var stock = sharedContext.objectWithID(stockID) as! Stock
        searchManager.title =  stock.company.name.uppercaseString
        
        var controllers = stockViewControllers
        
        // Remove Company
        if stock.type != "Equity" {
            controllers.removeAtIndex(1)
        }
        
        // Inject stock object in child controllers
        for navigationController in controllers as! [UINavigationController] {
            let controller = navigationController.childViewControllers.first! as! UIViewController
            
            switch controller {
            case let stockDetailsVC as StockDetailViewController:
                stockDetailsVC.stock = stock
            case let companyVC as CompanyViewController:
                companyVC.stock = stock
            case let newsVC as StockNewsViewController:
                newsVC.stock = stock
            default: println("no injection")
            }
        }
        
        // Update view controllers
        setViewControllers(controllers, animated: true)
    }
    
    // MARK: - SearchViewControllerDelegate
    func didBeginSearch() {
        
        searchManager.showResults()
    }
    
    func didEndEditing() {
        
        searchManager.closeResults()
        CoreDataStackManager.sharedInstance().saveContext()
    }

    func didSelectStock(stockID: NSManagedObjectID) {
        
        self.stockID = stockID
        setUpViewControllers()
        let controller = selectedViewController!.childViewControllers.first! as! StockInfoPresentation
        controller.loadPresentation()
    }
    
    func didWatchStock() {
        
        searchManager.closeResults()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func didUnWatchStock() {
        
        searchManager.closeResults()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
}

// MARK: - StockInfoPresentation Protocol
/* This should be implemented by all child controllers */
protocol StockInfoPresentation {
    
    // Load View Content
    func loadPresentation()
}
