//
//  CompanyViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 21/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import MapKit

class CompanyViewController: UITableViewController, StockInfoPresentation, UITextViewDelegate {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var sectorLabel: UILabel!
    @IBOutlet weak var industryLabel: UILabel!
    @IBOutlet weak var addressLabel: UIButton!
    @IBOutlet weak var webSiteLabel: UIButton!
    
    internal var stock: Stock!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set estimated height
        tableView.estimatedRowHeight = 35.0
        tableView.rowHeight = UITableViewAutomaticDimension
        title = "Company"
        
        // Add background table
        let background = UIImageView(image: UIImage(named: "background"))
        background.frame = tableView.bounds
        tableView.backgroundView = background
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load info
        parentViewController?.navigationController?.setNavigationBarHidden(false, animated: true)
        loadCompanyInfo()
        downloadCompanyInfo()
    }

    // MARK: - Set view content
    func loadCompanyInfo() {
        
        let attributedString = NSMutableAttributedString(string: stock.company.overview)
        let paragraphStyle = NSMutableParagraphStyle()
        let range = NSMakeRange(0, count(stock.company.overview))
        paragraphStyle.lineSpacing = ScreenSettings.SFLineSpacing
        paragraphStyle.alignment = NSTextAlignment.Justified
        attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: range)
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue-Light", size: ScreenSettings.SFPreferedFontSize)!, range: range)
            
        descriptionLabel.attributedText = attributedString
        descriptionLabel.textColor = UIColor.whiteColor()
        
        sectorLabel.text = stock.company.sector
        industryLabel.text = stock.company.industry
        addressLabel.setTitle(stock.company.address, forState: UIControlState.Normal)
        webSiteLabel.setTitle(stock.company.webPage, forState: UIControlState.Normal)

        tableView.reloadData()
    }
    
    // MARK: - Download content
    func downloadCompanyInfo() {
        
        YahooClient.sharedInstance().getCompanyProfile(stock.symbol) { result, error in
            
            if let error = error {
                // Show error
                dispatch_async(dispatch_get_main_queue()) {
                    let message = UIAlertView(title: "An Error Ocurred", message: error, delegate: nil, cancelButtonTitle: "OK")
                    message.show()
                }
            }
            else if let result = result {
                
                var resultDict = result
                if let address = result[Company.Keys.address] as? String {
                    resultDict[Company.Keys.address] = ", ".join(Formatter.getValuesFromURL(address))
                }
                self.stock.company.mergeValues(resultDict)
                dispatch_async(dispatch_get_main_queue()) {
                    
                    // Update view content
                    self.loadCompanyInfo()
                    if self.stock.watched {
                        self.stock.company.managedObjectContext?.save(nil)
                    }
                }
            }
        }
    }
    
    // MARK: - StockInfoPresentation protocol
    func loadPresentation() {
        
        loadCompanyInfo()
        downloadCompanyInfo()
    }
    
    // MARK: - Show Company Location
    @IBAction func showLocation(sender: UIButton) {
        
        if stock.company.latitude != 0 && stock.company.longitude != 0 {
            self.performSegueWithIdentifier("showMap", sender: self.stock)
        }
        else if !stock.company.address.isEmpty {
            
            // Initialize GLGeocoder
            let geocoder = CLGeocoder()
            // Geocode address String
            geocoder.geocodeAddressString(stock.company.address) { (placemarks, error) in
                // Show error description
                if error != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        let message = UIAlertView(title: "An Error Ocurred", message: "Unable to find company location", delegate: nil, cancelButtonTitle: "OK")
                        message.show()
                    }
                }
                else {
                    // Hide activity mesage and push next resource view controller passing placemarks results
                    dispatch_async(dispatch_get_main_queue()) {
                        let placemark = placemarks[0] as! CLPlacemark
                        self.stock.company.latitude = placemark.location.coordinate.latitude
                        self.stock.company.longitude = placemark.location.coordinate.longitude
                        self.stock.company.managedObjectContext?.save(nil)
                        self.performSegueWithIdentifier("showMap", sender: self.stock)
                    }
                }
            }
        }
    }
    
    // MARK: - Open company webpage
    @IBAction func openWebSite(sender: UIButton) {
        
        let webVC = storyboard?.instantiateViewControllerWithIdentifier("webView") as! WebViewController
        webVC.link = stock.company.webPage
        webVC.contentType = .WebPage
        presentViewController(webVC, animated: true, completion: nil)
        
    }
    
    // MARK: - TableView Delegate
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        parentViewController?.navigationController?.setNavigationBarHidden(true, animated: true)
        if segue.identifier == "showMap" {
            let mapVC = segue.destinationViewController as! MapViewController
            mapVC.stock = stock
        }
    }
    

}
