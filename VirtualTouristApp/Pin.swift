//
//  Pin.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import Foundation

//MARK: Pin

struct Pin {
    
    //MARK: Properties
    let annotationID: String?
    let annotationTitle: String?
    let latitude: Double
    let longitude: Double
    let page: Int64?
    let perPage: Int64?
    
    //MARK: Initializers
    
    //construct a Pin from a dictionary
    
    init(dictionary: [String:AnyObject]) {
        annotationID = dictionary[FlickrClient.Constants.JSONResponseKeys.annotationID] as? String
        annotationTitle = dictionary[FlickrClient.Constants.JSONResponseKeys.annotationTitle] as? String
        latitude = dictionary[FlickrClient.Constants.JSONResponseKeys.latitude] as! Double
        longitude = dictionary[FlickrClient.Constants.JSONResponseKeys.longitude] as! Double
        page = dictionary[FlickrClient.Constants.JSONResponseKeys.page] as? Int64
        perPage = dictionary[FlickrClient.Constants.JSONResponseKeys.perPage] as? Int64
    }
    
    static func pinsFromResults(results: [[String:AnyObject]]) -> [Pin] {
        
        var pins = [Pin]()
        
        // iterate through results array of dictionaries, each result is a dictionary
        for result in results {
            pins.append(Pin(dictionary: result))
        }
        
        return pins
    }

    
}