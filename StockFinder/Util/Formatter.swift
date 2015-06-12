//
//  Formatter.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 31/05/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Helper class to get String Formats and Values

import Foundation

class Formatter {
    
    // Returns the number contained in a string
    class func getStringNumber(string: String) -> NSString {
        let regex: String = "(/+|-)*[0-9]+(.[0-9]*)"
        let number = Formatter.matchesForRegexInText(regex, text: string).first ?? ""
        return number as NSString
    }
    
    // Break down url parameters and store them in an array
    class func getValuesFromURL(stringURL: String) -> [String] {
        var values = [String]()
        var url = stringURL.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let parameters = url.componentsSeparatedByString("&")
        
        for parameter in parameters {
            values.append(parameter.componentsSeparatedByString("=").last!)
        }
        return values
    }
    
    // Format single string removing white spaces
    class func getFormattedString(string: String) -> String? {
        
        let newString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return newString.isEmpty ? nil : newString
    }
    
    // Extract string regex matches
    class func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
        let regex = NSRegularExpression(pattern: regex, options: nil, error: nil)!
        let nsString = text as NSString
        let results = regex.matchesInString(text, options: nil, range: NSMakeRange(0, nsString.length))
            as! [NSTextCheckingResult]
        return map(results) { nsString.substringWithRange($0.range)}
    }
    
    // Get time past from a given date to current date
    class func getStringTimeFromDate(date: NSDate) -> String {
        
        let calendar = NSCalendar.currentCalendar()
        let currentDate = NSDate()
        let components = calendar.components(NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute , fromDate: date, toDate: currentDate, options: NSCalendarOptions.allZeros)
        
        if components.month > 0 {
            return "\(components.month) months ago"
        }
        if components.day > 0 {
            return "\(components.day) days ago"
        }
        else if components.hour > 0 {
            return "\(components.hour) hours ago"
        }
        else if components.minute > 0 {
            return "\(components.minute) minutes ago"
        }
        return ""
        
    }
    
    // Get string date for a given date using specific date format
    class func getStringFromDate(date: NSDate) -> String {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM dd, hh:mm a zzz"
        return formatter.stringFromDate(date)
    }
    
    // Get date for a given string using specific date format
    class func getDateFromString(stringDate: String) -> NSDate? {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEE,   dd MMM yy HH:mm:ss Z"
        return formatter.dateFromString(stringDate)
    }
    
}