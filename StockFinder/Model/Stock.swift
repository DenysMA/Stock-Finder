//
//  Stock.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 04/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import CoreData

@objc(Stock)

class Stock: NSManagedObject {
    
    struct Keys {
        static let symbol = "symbol"
        static let date = "time"
        static let price = "price"
        static let change = "change"
        static let changeAvg = "changeAvg"
        static let dateAH = "timeAH"
        static let priceAH = "priceAH"
        static let changeAH = "changeAH"
        static let changeAvgAH = "changeAvgAH"
        static let previousClose = "previosClose"
        static let open = "open"
        static let bid = "bid"
        static let bidSize = "bidSize"
        static let ask = "ask"
        static let askSize = "askSize"
        static let yearTarget = "1yTargetEst"
        static let beta = "beta"
        static let earningsDate = "earningsDate"
        static let wkStartRange = "52wkStartRange"
        static let wkEndRange = "52wkEndRange"
        static let lowest = "lowest"
        static let highest = "highest"
        static let volume = "volume"
        static let volumeAvg = "volumeAvg"
        static let marketCap = "marketCap"
        static let pe = "pe"
        static let eps = "eps"
        static let divYield = "divYield"
        static let exchange = "exchDisp"
        static let type = "typeDisp"
        static let chart = "image"
        static let watched = "watched"
        static let mainIndex = "mainIndex"
        static let region = "region"
        static let chgIndicator = "chgIndicator"
        static let downInd = "DOWN"
    }
    
    // Managed variables
    @NSManaged var symbol: String
    @NSManaged var exchange: String
    @NSManaged var type: String
    @NSManaged var price: String
    @NSManaged var change: Float
    @NSManaged var changeAvg: Float
    @NSManaged var priceAH: String
    @NSManaged var changeAH: String
    @NSManaged var changeAvgAH: String
    @NSManaged var dateAH: String?
    @NSManaged var open: String
    @NSManaged var previousClose: String
    @NSManaged var bid: String
    @NSManaged var bidSize: String
    @NSManaged var ask: String
    @NSManaged var askSize: String
    @NSManaged var yearTarget: String
    @NSManaged var beta: String
    @NSManaged var earningsDate: String
    @NSManaged var wkStartRange: String
    @NSManaged var wkEndRange: String
    @NSManaged var pe: String
    @NSManaged var eps: String
    @NSManaged var divYield: String
    @NSManaged var highest: String
    @NSManaged var lowest: String
    @NSManaged var mktCap: String
    @NSManaged var volume: String
    @NSManaged var volumeAvg: String
    @NSManaged var chartURL: String
    @NSManaged var stockDate: String
    @NSManaged var watched: Bool
    @NSManaged var mainIndex: Bool
    @NSManaged var region: Int64
    @NSManaged var order: Int64
    @NSManaged var company: Company
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: - Initializer with dictionary
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Stock", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        symbol = dictionary[Keys.symbol] as! String
        mergeValues(dictionary)
        company = Company(dictionary: dictionary, context: context)
    }
    
    // MARK: - Merge method
    
    func mergeValues(dictionary: [String: AnyObject]) {
    
        // Dictionary
        exchange = dictionary[Keys.exchange] as? String ?? exchange
        type = dictionary[Keys.type] as? String ?? type
        price = dictionary[Keys.price] as? String ?? price
        change = dictionary[Keys.change]?.floatValue ?? change
        priceAH = dictionary[Keys.priceAH] as? String ?? priceAH
        changeAH = dictionary[Keys.changeAH] as? String ?? changeAH
        changeAvgAH = dictionary[Keys.changeAvgAH] as? String ?? changeAvgAH
        dateAH = dictionary[Keys.dateAH] as? String ?? dateAH
        open = dictionary[Keys.open] as? String ?? open
        previousClose = dictionary[Keys.previousClose] as? String ?? previousClose
        bid = dictionary[Keys.bid] as? String ?? bid
        bidSize = dictionary[Keys.bidSize] as? String ?? bidSize
        ask = dictionary[Keys.ask] as? String ?? ask
        askSize = dictionary[Keys.askSize] as? String ?? askSize
        yearTarget = dictionary[Keys.yearTarget] as? String ?? yearTarget
        beta = dictionary[Keys.beta] as? String ?? beta
        earningsDate = dictionary[Keys.earningsDate] as? String ?? earningsDate
        wkStartRange = dictionary[Keys.wkStartRange] as? String ?? wkStartRange
        wkEndRange = dictionary[Keys.wkEndRange] as? String ?? wkEndRange
        pe = dictionary[Keys.pe] as? String ?? pe
        eps = dictionary[Keys.eps] as? String ?? eps
        divYield = dictionary[Keys.divYield] as? String ?? divYield
        highest = dictionary[Keys.highest] as? String ?? highest
        lowest = dictionary[Keys.lowest] as? String ?? lowest
        mktCap = dictionary[Keys.marketCap] as? String ?? mktCap
        volume = dictionary[Keys.volume] as? String ?? volume
        volumeAvg = dictionary[Keys.volumeAvg] as? String ?? volumeAvg
        stockDate = dictionary[Keys.date] as? String ?? ""
        
        if let region = dictionary[Keys.region]?.integerValue {
            self.region = Int64(region)
        }
        
        if let watched = dictionary[Keys.watched] as? Bool {
            self.watched = watched
            order = watched ? getStockOrder() : 0
        }
        
        if let changeAvg = dictionary[Keys.changeAvg] as? String {
            self.changeAvg = Formatter.getStringNumber(changeAvg).floatValue
        }
        
        if let index = dictionary[Stock.Keys.mainIndex] as? String {
            self.mainIndex = true
        }
    }
    
    // MARK: - Get next order for a stock in watch list
    func getStockOrder() -> Int64 {
        
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Stock")
        fetchRequest.predicate = NSPredicate(format: "watched = true")
        fetchRequest.includesSubentities = false
        let count = CoreDataStackManager.sharedInstance().managedObjectContext!.countForFetchRequest(fetchRequest, error: error)
        // Check for Errors
        if count == NSNotFound {
            return 0
        }
        return count + 1
    }
    
    
}