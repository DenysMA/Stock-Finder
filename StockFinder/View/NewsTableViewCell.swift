//
//  NewsTableViewCell.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 06/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Table Cell used for News VC

import UIKit

class NewsTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var newsImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
}
