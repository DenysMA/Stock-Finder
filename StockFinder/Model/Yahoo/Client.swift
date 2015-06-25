//
//  Client.swift
//  OnTheMap
//
//  Created by Denys Medina Aguilar on 30/03/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation
import UIKit

class Client {
    
    /* Shared session */
    let session: NSURLSession = NSURLSession.sharedSession()
    
    /* Client base URL */
    var baseURL : String = ""
    
    // Initializer with URL String
    init(baseUrlString : String) {
        baseURL = baseUrlString
    }
    
    // MARK: - GET
    
    func taskForGETMethod(method: String, parameters: [String : AnyObject]?, headers: [String : String], parseResponse: Bool? = true, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        // Set headers for GET method
        if parseResponse!.boolValue {
            var headers = headers
            headers["Accept"] = "application/json"
        }
        
        
        // Call generic method with GET type and parameters
        
        return taskForMethod("GET", method: method, parameters: parameters, headers: headers, body: nil, parseResponse:parseResponse, completionHandler: completionHandler)
    }
    
    // MARK: - POST
    
    func taskForPOSTMethod(method: String, parameters: [String : AnyObject]?, headers: [String : String], jsonBody: [String:AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {

        // Set headers for POST method
        
        var headers = headers
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        
        // Call generic method with POST type and parameters
        
        return taskForMethod("POST", method: method, parameters: parameters, headers: headers, body: jsonBody, completionHandler: completionHandler)
    }
    
    // MARK: - PUT
    
    func taskForPUTMethod(method: String, parameters: [String : AnyObject]?, headers: [String : String], jsonBody: [String:AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        // Set headers with PUT method
        
        var headers = headers
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        
        // Call generic method with PUT type and parameters
        
        return taskForMethod("PUT", method: method, parameters: parameters, headers: headers, body: jsonBody, completionHandler: completionHandler)
    }
    
    // MARK: - Generic Task
    
    func taskForMethod(restMethod: String ,method: String, parameters: [String : AnyObject]?, headers: [String : String], body: [String:AnyObject]?, parseResponse: Bool? = true, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        // Set complete URL
        var urlString = baseURL + method
        
        // Show network actvity indicator
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Add url parameters
        if let parameters = parameters {
            urlString += Client.escapedParameters(parameters)
        }
        
        // Create request and specify type of HTTP method
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        var jsonifyError: NSError? = nil
        request.HTTPMethod = restMethod
        
        // Set headers
        var headers = headers
        
        for (header, value) in headers {
            request.addValue(value, forHTTPHeaderField: header)
        }
        
        // Set json body parameters
        
        if let jsonBody = body {
            
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(jsonBody, options: nil, error: &jsonifyError)
        }
        
        NSLog("Request \(urlString)")

        // Create data request
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            // Check for connection errors
            
            if let error = downloadError {
                
                let userInfo = [NSLocalizedDescriptionKey : "Unable to connect to the server. Please verify your internet connection"]
                let error = NSError(domain: "Connection Error", code: error.code, userInfo: userInfo)
                completionHandler(result: nil, error: error)
                
                NSLog("Download Error. \(downloadError)")
                
            } else {
                
                // Validate if there is an http error code
                if let httpResponse = response as? NSHTTPURLResponse {
                    
                    // If no error return parsed json
                    
                    if self.validateHttpCode(httpResponse.statusCode) {
                        
                        if parseResponse!.boolValue {
                            
                            self.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
                        }
                        else {
                            
                            completionHandler(result: data, error: nil)
                        }
                    }
                    else {
                        
                        // If there is an error, parse it properly and return a new error
                        
                        let newError = self.errorForData(data, httpStatus: httpResponse.statusCode)
                        completionHandler(result: nil, error: newError)
                    }
                    
                }
            }
            
            // Hide activity indicator
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        // Resume task
        task.resume()
        
        return task

    }
    
    // MARK: - Helpers
    
    /* Helper: Given a response with error, return a Client- Specific error. This method should be override for every Client according to their error managment. */
    
    func errorForData(data: NSData?, httpStatus: Int) -> NSError {
        
        let userInfo = [NSLocalizedDescriptionKey : "Error getting response from server http \(httpStatus)"]
        return NSError(domain: "Client Error", code: 1, userInfo: userInfo)
    }
    
    /* Given an httpCode, verify if there is an error or not */
    func validateHttpCode(httpCode: Int) ->Bool {
        
        var result = false
        
        switch httpCode {
            // 2xx codes are treat as success
            case 200,201,202,203,204,205,206: result = true
            
            // Other codes are treat as errors
            default: result = false
        }
        
        return result
        
    }
    
    /* Helper: Given raw JSON, return a usable Foundation object */
    func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    /* Helper: Substitute the key for the value that is contained within the method name */
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    /* Helper: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }

}