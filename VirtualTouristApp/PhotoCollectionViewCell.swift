//
//  PhotoCollectionViewCell.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 8/3/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    
}
