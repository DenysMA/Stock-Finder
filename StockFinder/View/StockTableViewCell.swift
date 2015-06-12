//
//  StockTableViewCell.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 14/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Table Cell used in Search Results

import UIKit

class StockTableViewCell: UITableViewCell {

    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var exchangeLabel: UILabel!
    @IBOutlet weak var watchButton: UIButton!
}
