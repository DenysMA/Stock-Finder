//
//  MarketOverviewVC.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 05/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

protocol MarketVCDelegate: class {
    
    func didSelectStock(stockID: NSManagedObjectID)
    func didBeginLoading()
    func didFinishLoading()
}

class MarketOverviewVC: UIViewController {

    @IBOutlet weak var marketCollection: UICollectionView!
    @IBOutlet weak var indexCollection: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var regionControl: UISegmentedControl!
    @IBOutlet weak var regionBottomConstraint: NSLayoutConstraint!
    
    private let indexMarketDS = IndexMarketDS()
    private let marketDS = MarketOverviewDS()
    private let gradientLayer = CAGradientLayer()
    
    internal weak var delegate: MarketVCDelegate?
    internal var state: State!
    internal var error: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set estimated size for collection
        let marketFlowLayout = marketCollection.collectionViewLayout as! UICollectionViewFlowLayout
        marketFlowLayout.estimatedItemSize = CGSizeMake(184, 30)
        
        // Set up Data Sources
        indexMarketDS.owner = self
        marketDS.owner = self
        
        regionBottomConstraint.constant = view.frame.height/3 - regionControl.frame.height - 15
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate index collection item size
        let indexFlowLayout = indexCollection.collectionViewLayout as! UICollectionViewFlowLayout
        indexFlowLayout.itemSize = CGSize(width: UIScreen.mainScreen().bounds.width * 0.30, height: 50)
        indexFlowLayout.invalidateLayout()
        indexCollection.updateConstraints()
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
        delegate?.didBeginLoading()
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
    
}
