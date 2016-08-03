//
//  PhotoAlbumViewController.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {
    
    //Properties:
    var photos: [AnyObject]!
    let annotation = MKPointAnnotation()
    
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var photoAlbumVC: UICollectionView!
    
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    
    @IBAction func newCollectionButton(sender: AnyObject) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        annotation.coordinate.latitude = FlickrClient.sharedInstance().latitude!
        annotation.coordinate.longitude = FlickrClient.sharedInstance().longitude!
        annotation.title = FlickrClient.sharedInstance().annotationTitle
        centerMapOnLocation(annotation, regionRadius: 500.0)
    
        mapView.delegate = self
        mapView.addAnnotation(annotation)
        
        //implement cell flowLayout
        //cellFlowLayout(self.view.frame.size)
        cellFlowLayout(photoAlbumVC.frame.size)
        
        photos = [AnyObject]()

    }
    
    func cellFlowLayout(size: CGSize) {
        print("cellFlowLayout called")
        let space: CGFloat = 1.5
        let dimension: CGFloat = size.width >= size.height ? (size.width - (5 * space)) / 6.0 : (size.width - (2 * space)) / 3.0
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        
    }
    
    //MARK: Collection View Methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
        //return fetchedResultsController.sections?.count ?? 0
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return photos.count
        
        /*
         let sectionInfo = fetchedResultsController.sections![section]
         
         print("number Of Cells: \(sectionInfo.numberOfObjects)")
         return sectionInfo.numberOfObjects
         */
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        cell.backgroundColor = UIColor.redColor()
        
        let photo = photos[indexPath.item]
        
        cell.imageView?.image = photo as? UIImage
        
        //configureCell(cell, atIndexPath: indexPath)
        
        return cell
        
        
        //cell.setText(meme.topText, bottomString: meme.bottomText)
        
        /////cell.sentMemeImageView?.image = meme.imageMeme
        
        //let imageView = UIImageView(image: meme.imageMeme)
        //cell.backgroundView = imageView
        
        
    }
    
    // MARK: - Configure Cell
    //TODO: Remove and/or change this code
    //SOMEONE ELSE'S SOLUTION
    /*
     func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
     
     var photoImage = UIImage()
     
     cell.imageView.image = nil
     
     let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
     
     // Set the Movie Poster Image
     
     if photo.imagePath == nil || photo.imagePath == "" {
     photoImage = UIImage(named: "VirtualTourist")!
     } else if photo.image != nil {
     photoImage = photo.image!
     } else { // This is the interesting case. The photo has an image name, but it is not downloaded yet.
     
     // Start the task that will eventually download the image
     let task = Flickr.sharedInstance().getFlickrImage(photo.imagePath!) { imageData, error in
     
     if let error = error {
     print("Image download error: \(error.localizedDescription)")
     }
     
     if let data = imageData {
     
     print("Image download successful")
     
     // Create the image
     let image = UIImage(data: data)
     
     // update the model, so that the information gets cashed
     photo.image = image
     
     // update the cell later, on the main thread
     
     dispatch_async(dispatch_get_main_queue()) {
     cell.imageView!.image = image
     }
     }
     }
     
     cell.taskToCancelifCellIsReused = task
     }
     
     cell.imageView!.image = photoImage
     
     
     // If the cell is "selected" it's color panel is grayed out
     if let _ = selectedIndexes.indexOf(indexPath) {
     cell.alpha = 0.05
     } else {
     cell.alpha = 1.0
     }
     }
     */
    
    /*
     override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
     // If a meme is selected in the collection view navigate to the detailMemeViewController to display the meme
     let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("DetailMemeViewController") as! DetailMemeViewController
     detailController.meme = self.memes[indexPath.row]
     self.navigationController!.pushViewController(detailController, animated: true)
     
     }
     */
    
    // MARK: - MKMapViewDelegate
    
    // "Right callout accessory view" created to NOT show, just the pin selected from previous view
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //Centers the map on a coordinate (with lat and lon) with requisite radius
    func centerMapOnLocation(location: MKPointAnnotation, regionRadius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

/*
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    //1
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let flickrPhoto =  photoForIndexPath(indexPath)
        //2
        if var size = flickrPhoto.thumbnail?.size {
            size.width += 10
            size.height += 10
            return size
        }
        return CGSize(width: 100, height: 100)
    }
    
    //3
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
}
*/


