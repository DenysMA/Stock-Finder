//
//  JSONFilter.swift
//  StockFinder
//
//  Created by Denys Medina Aguilar on 28/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Helper class to filter JSON and XML data

import Foundation

// MARK: - JSON Parameter filter, used to extract json values in long JSON documents
struct ParameterFilter {
    
    let attributeName: String
    let attributeContent: String
    let elementName: String
    let otherValues: String?
    let alias: String
    let occurrence: Int?
    
    init(attributeName:String? = "class", attributeContent: String = "", elementName: String, otherValues: String? = nil, occurrence: Int? = nil, alias: String) {
        
        self.attributeName = attributeName!
        self.attributeContent = attributeContent
        self.elementName = elementName
        self.otherValues = otherValues
        self.alias = alias
        self.occurrence = occurrence
    }
}

// MARK: - XML filter, used to extract html and strings values in long XML documents
struct XPathFilter {
    
    let xpath: String
    let attribute: String?
    let alias: String
    
    init(xpath:String, attribute: String?, alias: String) {
        
        self.xpath = xpath
        self.attribute = attribute
        self.alias = alias
    }
}

class DataFilter: NSObject {
    
    // MARK: - JSON Filter method
    
    class func getStringValuesFromDictionary(JSONContent: AnyObject, filters:[ParameterFilter]) -> AnyObject {
        
        var dictionaryValues = [String: AnyObject]()
        var dictionaryArray = [[String: AnyObject]]()
        
        switch( JSONContent ) {
            
        case let content as [AnyObject]:
            
            for element in content {
                
                if let dictionary = element as? [String: AnyObject] {
                
                    var valuesToAdd: AnyObject = DataFilter.getStringValuesFromDictionary(dictionary, filters: filters)
                    if let values = valuesToAdd as? [String: AnyObject] {
                        if dictionaryValues.count == filters.count {
                            dictionaryArray.append(dictionaryValues)
                            dictionaryValues = [String: AnyObject]()
                            
                        }
                        dictionaryValues.add(values)
                    }
                    else if let values = valuesToAdd as? [[String: AnyObject]] {
                        dictionaryArray = dictionaryArray + values
                    }
                }
            }
        
        case let content as Dictionary<String, AnyObject>:
            
            for (key,value) in content {
                
                if let value = value as? String {
                    
                    var filtered = filters.filter() { parameter -> Bool in
                        if let result = value.rangeOfString(parameter.attributeContent, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)?.isEmpty {
                            return !result
                        }
                        return false
                    }
                    
                    for filter in filtered {
                        
                        var components = filter.elementName.componentsSeparatedByString(".")
                        let lastComponent = components.last!
                        components.removeLast()
                        
                        var dic = content
                        
                        for element in components {
                            
                            if let dictionary = dic[element] as? [String: AnyObject] {
                                dic = dictionary
                                
                            }else if let arrayElement = DataFilter.getOccurrence(element) {
                                let result = dic[arrayElement.element] as! [AnyObject]
                                if arrayElement.occurrence < result.count {
                                    dic = result[arrayElement.occurrence] as! [String: AnyObject]
                                }
                            }
                        }
                    
                        if dictionaryValues.count == filters.count {
                            dictionaryArray.append(dictionaryValues)
                            dictionaryValues = [String: AnyObject]()
                            
                        }
                        
                        if let result = dic[lastComponent] as? String {
                
                            dictionaryValues[filter.alias] = Formatter.getFormattedString(result)
                        }
                        else if let arrayElement = DataFilter.getOccurrence(lastComponent) {
                            if let result = dic[arrayElement.element] as? [AnyObject] {
                                
                                if let dictionary = result[arrayElement.occurrence] as? [String:AnyObject] {
                                    dictionaryValues[filter.alias] = dictionary
                                }
                                else if let stringObject = result[arrayElement.occurrence] as? String {
                                    dictionaryValues[filter.alias] = Formatter.getFormattedString(stringObject)
                                }
                            }
                        }
                        else {
                            dictionaryValues[filter.alias] = dic[lastComponent]
                        }
                    }
                }
                else if value is [AnyObject] || value is [String: AnyObject] {
                    
                    var valuesToAdd: AnyObject = DataFilter.getStringValuesFromDictionary(value, filters: filters)
                    if let values = valuesToAdd as? [String: AnyObject] {
                        
                        if dictionaryValues.count == filters.count {
                            dictionaryArray.append(dictionaryValues)
                            dictionaryValues = [String: AnyObject]()
                            
                        }
                        dictionaryValues.add(values)
                    }
                    else if let values = valuesToAdd as? [[String: AnyObject]] {
                        dictionaryArray = dictionaryArray + values
                    }
                }
            }
            
        default: NSLog("Invalid content \(JSONContent)")
            
        }
        
        if !dictionaryArray.isEmpty {
            if !dictionaryValues.isEmpty {
                dictionaryArray.append(dictionaryValues)
            }
            return dictionaryArray
        }
        else {
            return dictionaryValues
        }
    }
    
    // MARK: - XML Filter method by Xpath
    
    class func getValuesFromData(content: NSData, filters:[XPathFilter]) -> [String: AnyObject] {
        var values = [String: AnyObject]()
        var error: NSErrorPointer = nil
        
        let document = GDataXMLDocument(data: content, options: 0, error: error)
        
        for filter in filters {
            
            var nodes = document.nodesForXPath(filter.xpath, namespaces: nil, error: error) ?? [GDataXMLElement]()
            
            if nodes.count == 1 {
                
                if let element = nodes[0] as? GDataXMLElement {
                    
                    if let attribute = filter.attribute {
                        
                        if attribute == "xml" {
                            
                            let newDocument = GDataXMLDocument(rootElement: element)
                            values[filter.alias] = newDocument.XMLData()
                        }
                        else {
                            values[filter.alias] = Formatter.getFormattedString(element.attributeForName(attribute).stringValue())
                        }
                        
                    }
                    else {
                        values[filter.alias] = Formatter.getFormattedString(element.stringValue())
                    }
                }
            }
            else if nodes.count > 0 {
                
                var parentNode = GDataXMLElement(XMLString: "<html><header/></html>", error: error)
                var bodyNode = GDataXMLElement(XMLString: "<body></body>", error: error)
                
                for element in nodes {
                    bodyNode.addChild(element as! GDataXMLNode)
                }
                
                parentNode.addChild(bodyNode)
                
                let newDocument = GDataXMLDocument(rootElement: parentNode)
                values[filter.alias] = newDocument.XMLData()
            }
            
        }
    
        return values
    }
    
    // MARK: - Method used in JSON filter to get an element and its position when looking inside an array
    
    class func getOccurrence(element: String) -> (element: String, occurrence: Int)? {
        let range = element.rangeOfString("[", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)
        
        if let range = range {
            let endRange = element.rangeOfString("]", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)!
            let occurrence = element.substringWithRange(Range<String.Index>(start: range.endIndex, end: endRange.startIndex))
            let string = element.substringToIndex(range.startIndex)
            return (string, occurrence.toInt()!)
        }
        
        return nil
    }
}

// MARK: - Dictionary extension

extension Dictionary {
    mutating func add(other:Dictionary) {
        for (key,value) in other {
            self[key] = value
        }
    }
}

