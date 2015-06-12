//
//  YahooConstants.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 26/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation

extension YahooClient {
    
    // summary company: select * from html where url='http://finance.yahoo.com/q/pr?s=AMX' and xpath= '//td[contains(@class,"yfnc_modtitlew1")]//p' limit 1
    
    
    // MARK: - Constants
    struct Constants {
        
        // MARK: URLs
        static let baseURL : String = "https://query.yahooapis.com/v1/public/yql/ldma/"
        static let symbolURL : String = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query={symbol}&callback=YAHOO.Finance.SymbolSuggest.ssCallback"
        static let chartURL = "http://chart.finance.yahoo.com/z"
        static let apiKey : String = "567fed0a53d49c808342bb39837274aa"
        static let dataFormat = "json"
        static let no_json_callback = "1"
    }
    
    // MARK: - Query Alias (YQL)
    struct QueryAlias {
        static let MarketSummary = "SFMarketSummary"
        static let Quotes = "SFQuotes"
        static let QuoteDetails = "SFQuoteDetails"
        static let CompanyProfile = "SFCompanyProfile"
        static let TopNews = "SFTopNews"
        static let CompanyNews = "SFCompanyNews"
        static let NewsMedia = "SFNewsMedia"
        static let NewsContent = "SFNewsContent"
        
    }
    
    // MARK: - Key Parameters
    struct KeyParameters {
        static let quotes = "quotes"
        static let symbol = "symbol"
        static let region = "region"
        static let link = "url"
        static let format = "format"
        static let chartSymbol = "s"
        static let chartSize = "z"
        static let chartTimeSpan = "t"
    }
}
