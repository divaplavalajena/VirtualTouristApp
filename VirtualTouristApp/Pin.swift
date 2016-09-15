//
//  Pin.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import Foundation
import CoreData
import MapKit


//MARK: Pin

class Pin: NSManagedObject {
    

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(annotation: MKPointAnnotation, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)!
        
        super.init(entity: entity, insertInto: context)
        
        latitude = annotation.coordinate.latitude as Double as NSNumber?
        longitude = annotation.coordinate.longitude as Double as NSNumber?
        annotationTitle = annotation.title
    }

        
}
