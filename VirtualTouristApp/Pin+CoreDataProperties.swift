//
//  Pin+CoreDataProperties.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 8/12/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var annotationTitle: String?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var photos: NSOrderedSet?

}
