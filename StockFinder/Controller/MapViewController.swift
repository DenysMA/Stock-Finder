//
//  MapViewController.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 01/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    internal var stock: Stock!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        title = stock.company.name.uppercaseString
        // Load Annotation
        loadAnnotation()
    }

    // MARK: - Load Company Location
    func loadAnnotation() {
        
        // Create annotation
        var coordinate = CLLocationCoordinate2D(latitude: stock.company.latitude, longitude: stock.company.longitude)
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = stock.company.name
        annotation.subtitle = stock.company.webPage
        mapView.addAnnotation(annotation)
        
        // Set region
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000)
        mapView.setRegion(region, animated: true)
    }
}
