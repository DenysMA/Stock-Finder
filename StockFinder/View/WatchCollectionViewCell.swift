//
//  WatchCollectionViewCell.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 18/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Collection cell used in Watch List

import UIKit

class WatchCollectionViewCell: UICollectionViewCell {
 
    @IBOutlet var exchangeLabel: UILabel!
    @IBOutlet var symbolLabel: UILabel!
    @IBOutlet var companyLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var changeLabel: UILabel!
    @IBOutlet var changeAvgLabel: UILabel!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var watchButtonConstraint: NSLayoutConstraint!
    
    func updateMenuOptions() {
        
        self.layoutIfNeeded()
        
        if self.watchButtonConstraint.constant == 0 {
            self.watchButtonConstraint.constant = 55
        }
        else {
            self.watchButtonConstraint.constant = 0
        }
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { self.layoutIfNeeded() }, completion: nil)
    }
}
