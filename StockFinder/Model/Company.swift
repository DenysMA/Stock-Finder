//
//  Company.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 04/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation

import CoreData

@objc(Company)

class Company: NSManagedObject {
    
    struct Keys {
        static let name = "name"
        static let sector = "sector"
        static let industry = "industry"
        static let employees = "employees"
        static let description = "description"
        static let address = "address"
        static let webpage = "webpage"
    }
    
    // Managed variables
    @NSManaged var name: String
    @NSManaged var overview: String
    @NSManaged var sector: String
    @NSManaged var industry: String
    @NSManaged var employees: String
    @NSManaged var address: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var webPage: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: - Initializer with dictionary
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Company", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        name = dictionary[Keys.name] as? String ?? "?"
        sector = dictionary[Keys.sector] as? String ?? ""
        industry = dictionary[Keys.industry] as? String ?? ""
        overview = dictionary[Keys.description] as? String ?? ""
        employees = dictionary[Keys.employees] as? String ?? "0"
        address = dictionary[Keys.address] as? String ?? ""
        webPage = dictionary[Keys.webpage] as? String ?? ""
    }
    
    // MARK: - Merge method
    
    func mergeValues(dictionary: [String: AnyObject]) {
        
        // Dictionary
        name = dictionary[Keys.name] as? String ?? name
        sector = dictionary[Keys.sector] as? String ?? sector
        industry = dictionary[Keys.industry] as? String ?? industry
        overview = dictionary[Keys.description] as? String ?? overview
        employees = dictionary[Keys.employees] as? String ?? employees
        address = dictionary[Keys.address] as? String ?? address
        webPage = dictionary[Keys.webpage] as? String ?? webPage
    }

}