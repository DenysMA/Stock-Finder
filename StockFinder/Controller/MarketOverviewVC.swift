//
//  MarketOverviewVC.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 05/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

protocol MarketVCDelegate {
    
    func didSelectStock(stockID: NSManagedObjectID)
    func didFinishLoading()
}

class MarketOverviewVC: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var marketCollection: UICollectionView!
    @IBOutlet weak var indexCollection: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var regionControl: UISegmentedControl!
    @IBOutlet weak var activityHeight: NSLayoutConstraint!
    
    private let indexMarketDS = IndexMarketDS()
    private let marketDS = MarketOverviewDS()
    private let gradientLayer = CAGradientLayer()
    
    internal var delegate: MarketVCDelegate?
    internal var state: State!
    internal var error: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set image gradient layer
        gradientLayer.colors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        imageView.layer.insertSublayer(gradientLayer, atIndex: 0)
        activityHeight.constant = 0
        
        // Set estimated size for collection
        let marketFlowLayout = marketCollection.collectionViewLayout as! UICollectionViewFlowLayout
        marketFlowLayout.estimatedItemSize = CGSizeMake(184, 30)
        
        // Set up Data Sources
        indexMarketDS.owner = self
        marketDS.owner = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate index collection item size
        let indexFlowLayout = indexCollection.collectionViewLayout as! UICollectionViewFlowLayout
        indexFlowLayout.itemSize = CGSize(width: UIScreen.mainScreen().bounds.width * 0.30, height: 50)
        indexFlowLayout.invalidateLayout()
        indexCollection.updateConstraints()
        gradientLayer.frame = imageView.bounds
    }
    
    // MARK: - Load content
    func loadMarketInfo() {
        
        indexMarketDS.loadData()
    }
    
    // Scroll to top
    func resetCollectionScroll() {
        if marketCollection.numberOfItemsInSection(0) > 0 {
            marketCollection.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Left, animated: false)
        }
    }
    
    // MARK: - Change Region
    @IBAction func changeRegion(sender: UISegmentedControl) {
        
        let image = UIImage(named: "region_\(sender.selectedSegmentIndex)")
        showIndicator()
        indexMarketDS.updatePredicate()
        marketDS.updatePredicate()
        indexMarketDS.loadData()
        
        UIView.transitionWithView(self.imageView,
            duration:1,
            options: UIViewAnimationOptions.TransitionCrossDissolve,
            animations: { self.imageView.image = image },
            completion: nil)
        
        resetCollectionScroll()
    }
    
    // MARK: - Activity Indicator methods
    func showIndicator() {
        
        if !activityIndicator.isAnimating() {
            view.layoutIfNeeded()
            activityHeight.constant = 37
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { self.view.layoutIfNeeded() }) { finished in
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.startAnimating()
                }
            }
        }
    }
    
    func hideIndicator() {
        view.layoutIfNeeded()
        activityHeight.constant = 0
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { self.view.layoutIfNeeded() }) { finished in
            dispatch_async(dispatch_get_main_queue()) {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
}
