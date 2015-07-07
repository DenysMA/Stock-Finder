//
//  YahooClientMO.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 03/06/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Client extension created to manage prefetching on different entities

import Foundation

extension YahooClient {
    
    // MARK: - Prefetch media content of news
    
    func prefetchMediaForNews(news: News) {
        
        // Get context
        let sharedContext = news.managedObjectContext!
        getNewsMedia(news.link) { result, error in
            
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    news.source = Formatter.getHostNameFromString(news.link)
                    sharedContext.save(nil)
                    NSLog("Error prefetching news media \(error)")
                }
            }
            else if let result = result {
                dispatch_async(dispatch_get_main_queue()) {
                    news.mergeValues(result)
                    sharedContext.save(nil)
                }
            }
        }
        
    }
    
}