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
    let imageTitle: String?
    let imageID: String!
    let imagePath: String!
   
    
    //MARK: Initializers
    
    //construct a Photo from a dictionary
    
    init(dictionary: [String:AnyObject]) {
        imageTitle = dictionary[FlickrClient.Constants.FlickrResponseKeys.Title] as? String
        imageID = dictionary[FlickrClient.Constants.FlickrResponseKeys.ID] as! String
        imagePath = dictionary[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
    }
    
    static func photosFromResults(results: [[String:AnyObject]]) -> [Photo] {
        
        var photos = [Photo]()
        
        // iterate through results array of dictionaries, each result is a dictionary
        for result in results {
            photos.append(Photo(dictionary: result))
        }
        
        return photos
    }
    
    
}