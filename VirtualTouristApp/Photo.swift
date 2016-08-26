//
//  Photo.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import Foundation
import CoreData

//MARK: Photo

class Photo: NSManagedObject {
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?){
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        imageID = dictionary[FlickrClient.Constants.FlickrResponseKeys.ID] as? String
        imagePath = dictionary[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as? String
        imageData = dictionary["imageData"] as? NSData
    }

}