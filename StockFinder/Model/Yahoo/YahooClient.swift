//
//  YahooClient.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 26/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation

class YahooClient: Client {
    
    var currentStock: Stock?
    
    // Returns a single instance of flirck client
    class func sharedInstance() -> YahooClient {
        
        struct Singleton {
            static var sharedInstance = YahooClient(baseUrlString : Constants.baseURL)
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }

    // MARK: - Market Summary (Indexes and Futures)
    
    func getMarketSummary(region: Int, completionHandler: (results: [[String: AnyObject]]?, error: String?) -> Void) -> NSURLSessionDataTask {
        
        let parameters = [KeyParameters.region : "\(region)", KeyParameters.format: "json"]
        
        let indexFilter: [ParameterFilter] = [
            ParameterFilter(attributeContent: "ticker-name", elementName: "span", alias: Company.Keys.name),
            ParameterFilter(attributeContent: "ms-price", elementName: "span.content", alias: Stock.Keys.price),
            ParameterFilter(attributeContent: "c63", elementName: "span.content", alias: Stock.Keys.change),
            ParameterFilter(attributeContent: "p43", elementName: "span.content", alias: Stock.Keys.changeAvg),
            ParameterFilter(attributeContent: "lead-summary-link", elementName: "href", alias: Stock.Keys.symbol),
            ParameterFilter(attributeContent: "lead-summary-link", elementName: "href", alias: Stock.Keys.mainIndex)]
        
        let instrumentFilter: [ParameterFilter] = [
            ParameterFilter(attributeContent: "Carousel-Item", elementName: "href", alias: Stock.Keys.symbol),
            ParameterFilter(attributeContent: "Carousel-Item", elementName: "span[0].content", alias: Company.Keys.name),
            ParameterFilter(attributeContent: "Carousel-Item", elementName: "span[1].content", alias: Stock.Keys.price),
            ParameterFilter(attributeContent: "Carousel-Item", elementName: "span[2].span.content", alias: Stock.Keys.changeAvg)]
        
        return taskForGETMethod(YahooClient.QueryAlias.MarketSummary, parameters: parameters, headers: [String:String]()) { result, error in
            
            if let error = error {
                
                //If error is diferent to cancelled send error details, otherwise means that task was cancelled by user
                if error.code != NSURLErrorCancelled {
                    completionHandler(results: nil, error: error.localizedDescription)
                    NSLog("Error \(error.debugDescription)")
                }
                else {
                    completionHandler(results: nil, error: nil)
                }
            }
            else {
                
                let indexes = DataFilter.getStringValuesFromDictionary(result, filters: indexFilter) as? [[String: AnyObject]]
                let instruments = DataFilter.getStringValuesFromDictionary(result, filters: instrumentFilter) as? [[String: AnyObject]]
                var results = [[String: AnyObject]]()
                
                if let instruments = instruments, indexes = indexes {
                    results = indexes + instruments
                }
                
                results = results.map() {
                    var stockDict = $0
                    let symbol = $0[Stock.Keys.symbol] as! String
                    stockDict[Stock.Keys.symbol] = symbol.componentsSeparatedByString("=").last!
                    stockDict[Stock.Keys.region] = region
                    return stockDict
                }
                
                completionHandler(results: results, error: nil)
            }
        }
    }
    
    // MARK: - Quote short summary
    
    func getQuotes(quotesList: String, completionHandler: (results: [[String: AnyObject]]?, error: String?) -> Void) -> NSURLSessionDataTask {
    
        let quotes = quotesList.stringByReplacingOccurrencesOfString("^", withString: "%5E", options: NSStringCompareOptions.allZeros, range: nil)
        let parameters = [KeyParameters.quotes : quotes, KeyParameters.format: "json"]
        
        let responseFilter: [ParameterFilter] =
        [ParameterFilter(attributeContent: "col-symbol", elementName: "span.button.data-flw-quote", alias: Stock.Keys.symbol),
            ParameterFilter(attributeContent: "col-time", elementName: "span.span.content", alias: Stock.Keys.date),
            ParameterFilter(attributeContent: "col-price", elementName: "span.span.content", alias: Stock.Keys.price),
            ParameterFilter(attributeContent: "col-change", elementName: "span.span.content", alias: Stock.Keys.change),
            ParameterFilter(attributeContent: "col-percent_change", elementName: "span.span.content", alias: Stock.Keys.changeAvg),
            ParameterFilter(attributeContent: "col-day_low", elementName: "span.span.content", alias: Stock.Keys.lowest),
            ParameterFilter(attributeContent: "col-day_high", elementName: "span.span.content", alias: Stock.Keys.highest),
            ParameterFilter(attributeContent: "col-volume", elementName: "span.span.content", alias: Stock.Keys.volume),
            ParameterFilter(attributeContent: "col-avg_daily_volume", elementName: "span.content", alias: Stock.Keys.volumeAvg),
            ParameterFilter(attributeContent: "col-market_cap", elementName: "span.span.content", alias: Stock.Keys.marketCap)]
        
        return taskForGETMethod(YahooClient.QueryAlias.Quotes, parameters: parameters, headers: [String:String]()) { result, error in
            
            if let error = error {
                
                if error.code != NSURLErrorCancelled {
                    completionHandler(results: nil, error: error.localizedDescription)
                    NSLog("Error \(error.debugDescription)")
                }
                else {
                    completionHandler(results: nil, error: nil)
                }
            }
            else if let result = result as? [String: AnyObject] {
    
                if let results = DataFilter.getStringValuesFromDictionary(result, filters: responseFilter) as? [[String: AnyObject]] {
                    completionHandler(results: results, error: nil)
                }
                else {
                    completionHandler(results: nil, error: "Error reading information from the server")
                }
            }
        }
    }
    
    // MARK: - Quote full summary
    
    func getQuoteDetails(symbol: String, completionHandler: (results: [String: AnyObject]?, error: String?) -> Void) -> NSURLSessionDataTask {
        
        let symbol = symbol.stringByReplacingOccurrencesOfString("^", withString: "%5E", options: NSStringCompareOptions.allZeros, range: nil)
        let parameters = [KeyParameters.symbol : symbol, KeyParameters.format: "json"]
        
        let responseFilter: [ParameterFilter] = [
            ParameterFilter(attributeContent: "yfs_l84", elementName: "content", alias: Stock.Keys.price),
            ParameterFilter(attributeContent: "yfs_c63", elementName: "content", alias: Stock.Keys.change),
            ParameterFilter(attributeContent: "yfs_c63", elementName: "img.alt", alias: Stock.Keys.chgIndicator),
            ParameterFilter(attributeContent: "yfs_p43", elementName: "content", alias: Stock.Keys.changeAvg),
            ParameterFilter(attributeContent: "time_rtq", elementName: "span.span.content", alias: Stock.Keys.date),
            ParameterFilter(attributeContent: "yfs_l86", elementName: "content", alias: Stock.Keys.priceAH),
            ParameterFilter(attributeContent: "yfs_c85", elementName: "content", alias: Stock.Keys.changeAH),
            ParameterFilter(attributeContent: "yfs_c86", elementName: "content", alias: Stock.Keys.changeAvgAH),
            ParameterFilter(attributeContent: "yfs_t54", elementName: "content", alias: Stock.Keys.dateAH),
            ParameterFilter(attributeContent: "table1", elementName: "tbody.tr[0].td.content", alias: Stock.Keys.previousClose),
            ParameterFilter(attributeContent: "table1", elementName: "tbody.tr[1].td.content", alias: Stock.Keys.open),
            ParameterFilter(attributeContent: "yfs_b00", elementName: "content", alias: Stock.Keys.bid),
            ParameterFilter(attributeContent: "yfs_b60", elementName: "content", alias: Stock.Keys.bidSize),
            ParameterFilter(attributeContent: "yfs_a00", elementName: "content", alias: Stock.Keys.ask),
            ParameterFilter(attributeContent: "yfs_a50", elementName: "content", alias: Stock.Keys.askSize),
            ParameterFilter(attributeContent: "table1", elementName: "tbody.tr[4].td.content", alias: Stock.Keys.yearTarget),
            ParameterFilter(attributeContent: "table1", elementName: "tbody.tr[5].td.content", alias: Stock.Keys.beta),
            ParameterFilter(attributeContent: "table1", elementName: "tbody.tr[6].td.content", alias: Stock.Keys.earningsDate),
            ParameterFilter(attributeContent: "yfs_g53", elementName: "content", alias: Stock.Keys.lowest),
            ParameterFilter(attributeContent: "yfs_h53", elementName: "content", alias: Stock.Keys.highest),
            ParameterFilter(attributeContent: "table2", elementName: "tbody.tr[1].td.span[0]", alias: Stock.Keys.wkStartRange),
            ParameterFilter(attributeContent: "table2", elementName: "tbody.tr[1].td.span[1]", alias: Stock.Keys.wkEndRange),
            ParameterFilter(attributeContent: "yfs_v53", elementName: "content", alias: Stock.Keys.volume),
            ParameterFilter(attributeContent: "yfs_j10", elementName: "content", alias: Stock.Keys.marketCap),
            ParameterFilter(attributeContent: "table2", elementName: "tbody.tr[3].td.content", alias: Stock.Keys.volumeAvg),
            ParameterFilter(attributeContent: "table2", elementName: "tbody.tr[5].td.content", alias: Stock.Keys.pe),
            ParameterFilter(attributeContent: "table2", elementName: "tbody.tr[6].td.content", alias: Stock.Keys.eps),
            ParameterFilter(attributeContent: "table2", elementName: "tbody.tr[7].td.content", alias: Stock.Keys.divYield)
        ]

        
        return taskForGETMethod(YahooClient.QueryAlias.QuoteDetails, parameters: parameters, headers: [String: String]()) { result, error in
         
            if let error = error {

                if error.code != NSURLErrorCancelled {
                    completionHandler(results: nil, error: error.localizedDescription)
                    NSLog("Error \(error.debugDescription)")
                }
                else {
                    completionHandler(results: nil, error: nil)
                }
            }
            else if let result = result as? [String: AnyObject] {
                
                if var results = DataFilter.getStringValuesFromDictionary(result, filters: responseFilter) as? [String: AnyObject] {
                    
                    if let chgIndicator = results[Stock.Keys.chgIndicator] as? String {
                        let multiplier: Float = chgIndicator.uppercaseString == Stock.Keys.downInd ? -1 : 1
                        results[Stock.Keys.change] = (results[Stock.Keys.change]!.floatValue * multiplier)
                        results[Stock.Keys.changeAvg] = (results[Stock.Keys.changeAvg]!.floatValue * multiplier)
                    }
                    completionHandler(results: results, error: nil)
                }
                else {
                    completionHandler(results: nil, error: "Error reading information from the server")
                }
            }
        }
    }
    
    // MARK: - Company Profile
    
    func getCompanyProfile(symbol: String, completionHandler: (results: [String: AnyObject]?, error: String?) -> Void) {
        
        let symbol = symbol.stringByReplacingOccurrencesOfString("^", withString: "%5E", options: NSStringCompareOptions.allZeros, range: nil)
        let parameters = [KeyParameters.symbol: symbol]
        
        let filters: [XPathFilter] = [
            XPathFilter(xpath: "//a[1]", attribute: "href", alias: Company.Keys.address),
            XPathFilter(xpath: "//a[contains(@href,'//biz.yahoo.com/p')]", attribute: nil, alias: Company.Keys.sector),
            XPathFilter(xpath: "//a[contains(@href,'//biz.yahoo.com/ic')]", attribute: nil, alias: Company.Keys.industry),
            XPathFilter(xpath: "(//td[@class='yfnc_tabledata1'])[last()]", attribute: nil, alias: Company.Keys.employees),
            XPathFilter(xpath: "//p[1]", attribute: nil, alias: Company.Keys.description),
            XPathFilter(xpath: "//a[text()='Home Page']", attribute: "href", alias: Company.Keys.webpage)
        ]
        
        taskForGETMethod(YahooClient.QueryAlias.CompanyProfile, parameters: parameters, headers: [String:String](), parseResponse: false) { result, error in
            
            if let error = error {
 
                if error.code != NSURLErrorCancelled {
                    completionHandler(results: nil, error: error.localizedDescription)
                    NSLog("Error \(error.debugDescription)")
                }
                else {
                    completionHandler(results: nil, error: nil)
                }
            }
            else {
                
                let results = DataFilter.getValuesFromData(result as! NSData, filters: filters)
                completionHandler(results: results, error: nil)
            }
        }
    }
    
    // MARK: - Top Finance News and Company News
    
    func getNews(symbol: String?, completionHandler: (results: [[String: AnyObject]]?, error: String?) -> Void) -> NSURLSessionDataTask {
        
        var parameters = [KeyParameters.format: "json"]
        var method = YahooClient.QueryAlias.TopNews
        
        if let symbol = symbol {
            let symbol = symbol.stringByReplacingOccurrencesOfString("^", withString: "%5E", options: NSStringCompareOptions.allZeros, range: nil)
            parameters[KeyParameters.symbol] = symbol
            method = YahooClient.QueryAlias.CompanyNews
        }
        
        return taskForGETMethod(method, parameters: parameters, headers: [String:String]()) { result, error in
            
            if let error = error {
        
                if error.code != NSURLErrorCancelled {
                    completionHandler(results: nil, error: error.localizedDescription)
                    NSLog("Error \(error.debugDescription)")
                }
                else {
                    completionHandler(results: nil, error: nil)
                }
            }
            else {
                
                if let result = result["query"] as? [String: AnyObject] {
                    let results = result["results"] as? [String: AnyObject]
                    if let items = results?["item"] as? [[String: AnyObject]] {
                        completionHandler(results: items, error: nil)
                        return
                    }
                    // No results found
                    completionHandler(results: nil, error: nil)
                    return
                }
                completionHandler(results: nil, error: "Error reading information from the server")
            }
        }
    }

    // MARK: - News media content
    
    func getNewsMedia(newsLink: String, completionHandler: (results: [String: AnyObject]?, error: String?) -> Void) -> Void {
        
        let parameters = [KeyParameters.link : newsLink.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!]
        
        let filters: [XPathFilter] = [
            XPathFilter(xpath: "//img[contains(@class,'provider') or contains(@class,'logo')]", attribute:"alt", alias: News.Keys.source),
            XPathFilter(xpath: "((//cite/span)[2]) or ((//cite/span)[2]/a)", attribute: nil, alias: News.Keys.credits),
            XPathFilter(xpath: "//iframe", attribute:"src", alias: News.Keys.videoURL),
            XPathFilter(xpath: "//meta[@itemprop='embedURL']", attribute:"content", alias: "video"),
            XPathFilter(xpath: "//img[contains(@height,'px')]", attribute: "src", alias:"image"),
            XPathFilter(xpath: "(//meta[contains(@itemprop,'image') or contains(@itemprop,'thumbnailUrl')])[1]", attribute: "content", alias: News.Keys.imageURL)
        ]
        
        taskForGETMethod(YahooClient.QueryAlias.NewsMedia, parameters: parameters, headers: [String:String](), parseResponse: false) { result, error in
            
            if let error = error {

                if error.code != NSURLErrorCancelled {
                    completionHandler(results: nil, error: error.localizedDescription)
                    NSLog("Error \(error.debugDescription)")
                }
                else {
                    completionHandler(results: nil, error: nil)
                }
            }
            else if let result = result as? NSData {
                
                let results = DataFilter.getValuesFromData(result, filters: filters)
                var dictionary = results
                dictionary[News.Keys.videoURL] = dictionary[News.Keys.videoURL] ?? dictionary["video"]
                dictionary[News.Keys.imageURL] = dictionary[News.Keys.imageURL] ?? dictionary["image"]
                completionHandler(results: dictionary, error: nil)
            }
            else {
                // No information returned
                completionHandler(results: nil, error: nil)
            }
        }
    }
    
    // MARK: - News text content
    
    func getNewsContent(newsLink: String, completionHandler: (results: [String: AnyObject]?, error: String?) -> Void) -> Void {
        
        let parameters = [KeyParameters.link : newsLink.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!]
        let filters: [XPathFilter] = [
            XPathFilter(xpath: "//results/*", attribute:"xml", alias: Content.Keys.content)
        ]
        
        taskForGETMethod(YahooClient.QueryAlias.NewsContent, parameters: parameters, headers: [String:String](), parseResponse: false) { result, error in
            
            if let error = error {

                if error.code != NSURLErrorCancelled {
                    completionHandler(results: nil, error: error.localizedDescription)
                    NSLog("Error \(error.debugDescription)")
                }
                else {
                    completionHandler(results: nil, error: nil)
                }
            }
            else if let result = result as? NSData {
                
                let results = DataFilter.getValuesFromData(result, filters: filters)
                completionHandler(results: results, error: nil)
            }
            else {
                // No information returned
                completionHandler(results: nil, error: nil)
            }
        }
    }
    
    // MARK: - Quote Chart
    
    func getChartData(symbol: String, timeSpan: String, completionHandler: (imageData: NSData?, error: String?) -> Void) -> NSURLSessionDataTask {
        
        var chartStringURL = YahooClient.Constants.chartURL
        let symbol = symbol.stringByReplacingOccurrencesOfString("^", withString: "%5E", options: NSStringCompareOptions.allZeros, range: nil)
        let parameters = [KeyParameters.chartSymbol : symbol, KeyParameters.chartSize: "l", KeyParameters.chartTimeSpan: timeSpan]
        
        // Add url parameters
        chartStringURL += YahooClient.escapedParameters(parameters)
        
        let chartURL = NSURL(string: chartStringURL)!
        let request = NSURLRequest(URL: chartURL)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
        
                if error.code != NSURLErrorCancelled {
                    completionHandler(imageData: nil, error: "Unable to connect to the server")
                    NSLog("Download Error. \(downloadError)")
                }
                else {
                    completionHandler(imageData: nil, error: nil)
                }
                
            } else {
                
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
}

// MARK: - Yahoo Finance Symbol Lookup Client

class YahooFinanceClient: Client {
    
    // Returns a single instance of flirck client
    class func sharedInstance() -> YahooFinanceClient {
        
        struct Singleton {
            static var sharedInstance = YahooFinanceClient(baseUrlString : YahooClient.Constants.symbolURL)
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: - Quotes by string
    
    func getSymbolsWithString(symbol: String, completionHandler: (results: [[String: AnyObject]]?, error: String?) -> Void) -> NSURLSessionDataTask {
        
        baseURL = YahooClient.subtituteKeyInMethod(YahooClient.Constants.symbolURL, key: YahooClient.KeyParameters.symbol, value: symbol)!
        
        return taskForGETMethod("", parameters: nil, headers: [String:String]()) { result, error in
            
            if let error = error {
                if error.code != NSURLErrorCancelled {
                    completionHandler(results: nil, error: error.localizedDescription)
                    NSLog("Error \(error.debugDescription)")
                }
                else {
                    completionHandler(results: nil, error: nil)
                }

            }
            else if let resultSet = result["ResultSet"] as? [String: AnyObject] {
                
                if let results = resultSet["Result"] as? [[String: AnyObject]] {
                    
                    completionHandler(results: results, error: nil)
                    return
                }
                else {
                    completionHandler(results: nil, error: "Error reading information from the server")
                }
            }
            
        }
    }
    
    // MARK: - Parse Yahoo Finance JSON
    
    override func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError? = nil
        
        // Skip the first 5 characters of the response
        
        let data = data.subdataWithRange(NSMakeRange(39, data.length - 40)) /* subset response data! */
        
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }

    
}
