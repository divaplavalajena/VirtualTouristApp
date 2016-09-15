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
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?){
        super.init(entity: entity, insertInto: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context)!
        super.init(entity: entity, insertInto: context)
        
        // Dictionary
        imageID = dictionary[FlickrClient.Constants.FlickrResponseKeys.ID] as? String
        imagePath = dictionary[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as? String
        imageData = dictionary["imageData"] as? Data
    }

}
