//
//  Photo.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import Foundation

//MARK: Photo

struct Photo {
    
    //MARK: Properties
    let imagePath: String?
    let imageTitle: String?
   
    
    //MARK: Initializers
    
    //construct a Photo from a dictionary
    
    init(dictionary: [String:AnyObject]) {
        imagePath = dictionary[FlickrClient.Constants.JSONResponseKeys.imagePath] as? String
        imageTitle = dictionary[FlickrClient.Constants.JSONResponseKeys.imageTitle] as? String
    }
    
    static func pinsFromResults(results: [[String:AnyObject]]) -> [Photo] {
        
        var pins = [Photo]()
        
        // iterate through results array of dictionaries, each result is a dictionary
        for result in results {
            pins.append(Photo(dictionary: result))
        }
        
        return pins
    }
    
    
}