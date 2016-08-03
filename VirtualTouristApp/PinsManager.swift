//
//  PinsManager.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import Foundation

class PinsManager {
    
    var pins: [Pin] = [Pin]()
    
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> PinsManager {
        struct Singleton {
            static var sharedInstance = PinsManager()
        }
        return Singleton.sharedInstance
    }
    
}