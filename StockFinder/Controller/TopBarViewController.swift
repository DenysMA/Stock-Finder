//
//  TopBarViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 14/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Search Bar View Controller

import UIKit

class TopBarViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textField = searchBar.valueForKey("searchField") as? UITextField
        textField?.textColor = UIColor.whiteColor()
    }

    // MARK: - Search Symbol
    @IBAction func search() {
        
        // Resize views and animate changes
        searchButton.hidden = true
        self.view.layoutIfNeeded()
        self.searchBarConstraint.constant = self.view.frame.width * 0.7
        self.searchBar.becomeFirstResponder()
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { self.view.layoutIfNeeded() }, completion: nil)
    }
    
    // Reset view constraints when search view is closed
    func restoreView() {
        
        // Reset constraints and animate changes
        searchBar.resignFirstResponder()
        searchBar.text = ""
        
        self.view.layoutIfNeeded()
        self.searchBarConstraint.constant = 0
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { self.view.layoutIfNeeded() }){ success in
            self.searchButton.hidden = false
        }
    }
}
