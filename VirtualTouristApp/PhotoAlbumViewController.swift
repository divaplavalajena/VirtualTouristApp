//
//  PhotoAlbumViewController.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    //Properties:
    var selectedIndexes = [NSIndexPath]()
    let annotation = MKPointAnnotation()
    var tappedPin: Pin!
    
    lazy var sharedContext: NSManagedObjectContext = {
        // Get the stack
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        return stack.context
    }()

    
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var photoAlbumVC: UICollectionView!
    
    //@IBOutlet var flowLayout: UICollectionViewFlowLayout!
    
    @IBAction func newCollectionButton(sender: AnyObject) {
        //TODO: implement this newCollectionButton with collectionItemAtIndexPath method detail
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Core Data implementation
        fetchedResultsController.delegate = self
        
        annotation.coordinate.latitude = tappedPin?.latitude as! Double
        annotation.coordinate.longitude = tappedPin?.longitude as! Double
    
        mapView.delegate = self
        mapView.addAnnotation(annotation)
        
        centerMapOnLocation(annotation, regionRadius: 500.0)
        
        //implement cell flowLayout
        //cellFlowLayout(photoAlbumVC.frame.size)
        
        //load saved pins
        do {
            try fetchedResultsController.performFetch()
            print("FRC called on viewDidLoad to perform fetch")
        } catch {
            print("There was an error fetching on viewDidLoad of PhotoAlbumVC")
        }
        

    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
            loadPhotoAlbum()
        } else {
            //TODO: add else statement to load photos from Core Data if FRC already has photos in it
            //load saved photos at pin location - how does Core Data know this?
            self.photoAlbumVC.reloadData()
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        // OR lay out the collection view so that the cells take up 1/3 of the width with no space between
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        //2 - defines minimum spacing between horizontal items
        flowLayout.minimumLineSpacing = 0.0
        //3 - defines minimum spacing between vertical items
        flowLayout.minimumInteritemSpacing = 0.0
        
        let width = floor(self.photoAlbumVC.frame.size.width/3)
        flowLayout.itemSize = CGSize(width: width, height: width)
        
        photoAlbumVC.collectionViewLayout = flowLayout
        
    }
    
    /*
    func cellFlowLayout(size: CGSize) {
        print("cellFlowLayout called")
        //Layout the collection view so that the cells take up 1/3 of the width with no space between
        
        // 1 - calculating the image dimensions
        //let space: CGFloat = 0.0
        //let dimension: CGFloat = size.width >= size.height ? (size.width - (5 * space)) / 6.0 : (size.width - (2 * space)) / 3.0
        
        // OR lay out the collection view so that the cells take up 1/3 of the width with no space between
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        //2 - defines minimum spacing between horizontal items
        flowLayout.minimumLineSpacing = 0.0
        //3 - defines minimum spacing between vertical items
        flowLayout.minimumInteritemSpacing = 0.0
        
        let width = floor(self.photoAlbumVC.frame.size.width/3)
        //let screenWidth = self.photoAlbumVC.bounds.size.width
        //let totalSpacing = flowLayout.minimumInteritemSpacing * 3.0
        //let imageSize = (screenWidth - totalSpacing) / 3.0
        
        //flowLayout.itemSize = CGSizeMake(dimension, dimension)
        flowLayout.itemSize = CGSize(width: width, height: width)
        
        photoAlbumVC.collectionViewLayout = flowLayout
    }
    */
    
    func loadPhotoAlbum() {
        print("loadPhotoAlbum called")
        
        // Get images from Flickr client
        FlickrClient.sharedInstance().getPagesFromFlickrBySearch(Double((tappedPin.latitude)!), longitude: Double((tappedPin.longitude)!), completionHandlerForFlickrPages:  { (randomPageNumber, error) in
            if let randomPageNumber = randomPageNumber {
                FlickrClient.sharedInstance().displayImagesFromFlickrBySearch(Double((self.tappedPin.latitude)!), longitude: Double((self.tappedPin.longitude)!), withPageNumber: randomPageNumber, completionHandlerForFlickrImages: { (photos, error) in
                    if let photos = photos {
                    
                        print("Network calls to Flickr successful, here is the photos array.")
                        print("This is how many photos are in the array: \(photos.count).")
                        print(photos)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            // parse the photos (array of dictionaries) and create Core Data objects
                            _ = photos.map() { (dictionary: [String: AnyObject]) -> Photo in
                                let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                                photo.pinData = self.tappedPin
                                self.saveToBothContexts()
                                return photo
                            }
                        }
                        
                    } else {
                        print("The error is in the second Flickr method getting the images. Error: \(error)")
                        //TODO: add error handling for second Flickr Method to screen???
                    }
                })
            } else {
                print("The error is in the first Flickr method getting the page number. Error: \(error)")
                //TODO: add error handling for first Flickr method to screen???
            }
        })

    }
    
    //MARK: Collection View Methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // return the number of sections
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // return the number of items
        
        return fetchedResultsController.sections![section].numberOfObjects ?? 21
        //(tappedPin.photos?.count)!
        //fetchedResultsController.sections![section].numberOfObjects ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = photoAlbumVC.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    
    // MARK: - Configure Cell
    
     func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        //if let cell = self.photoAlbumVC.cellForItemAtIndexPath(indexPath) as? PhotoCollectionViewCell {
     
         var photoImage = UIImage(named: "placeholderImageCamera-300px.png")
         
         cell.imageView.image = nil
         
         let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
         
         // Set the Flickr Image
         if photo.imagePath == nil || photo.imagePath == "" {
             photoImage = UIImage(named: "placeholderImageCamera-300px.png")!
            
         } else if photo.imageData != nil {
             //TODO: Fix this so it checks Core Data before downloading from Flickr
             photoImage = UIImage(data: photo.imageData!)
         } else {
            
             // Start the task that will eventually download the image
             let task = FlickrClient.sharedInstance().getFlickrImage(FlickrClient.Constants.Flickr.imageSize,
                                                                     filePath: photo.imagePath!,
                                                                     completionHandlerForImage: { (imageData, error) in
             
             if let error = error {
                 print("Image download error: \(error.localizedDescription)")
                photoImage = UIImage(named: "placeholderImageCamera-300px.png")
                dispatch_async(dispatch_get_main_queue()) {
                    cell.imageView.image = photoImage
                }
             }
                
             
                if let data = imageData {
                    print("Image download successful")
                    // Create the image
                    let image = UIImage(data: data)
                    // save in Core Data
                    photo.imageData = data
                    
                    self.saveToBothContexts()
                    
                    // update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = image
                    }
                }
             })
             
                 cell.taskToCancelifCellIsReused = task
         }
         
         cell.imageView!.image = photoImage
    //}
    
         // If the cell is "selected" it's color panel is grayed out
         if let _ = selectedIndexes.indexOf(indexPath) {
             cell.alpha = 0.05
         } else {
             cell.alpha = 1.0
         }
     }
    
    func saveToBothContexts() {
        // Save pin data to both contexts
        let stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
        stack.saveBothContexts()
    }
    
    //TODO: Implement collectionView didSelectItemAtIndexPath for New Collection button ****************************************************
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
    

    
    // MARK: NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageID", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pinData == %@", self.tappedPin!)
        print("This is the fetchedResultsController being created with the tappedPin.latitude: \(self.tappedPin.latitude)")
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    //TODO: Do I need both of these??
    /*
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.photoAlbumVC.reloadData()
    }
    */
    
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.photoAlbumVC.reloadData()
    }
 
 
    // TODO: Determine if I need these methods
    /*
    func controller(controller: NSFetchedResultsController,
                    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                                     atIndex sectionIndex: Int,
                                             forChangeType type: NSFetchedResultsChangeType) {
        
        let set = NSIndexSet(index: sectionIndex)
        
        switch (type){
            
        case .Insert:
            photoAlbumVC?.insertSections(set)
            
        case .Delete:
            photoAlbumVC?.deleteSections(set)
            
        default:
            // irrelevant in our case
            break
            
        }
    }
    
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?) {
        
        
        
        switch(type){
            
        case .Insert:
            photoAlbumVC?.insertItemsAtIndexPaths([newIndexPath!])
            
        case .Delete:
            photoAlbumVC?.deleteItemsAtIndexPaths([indexPath!])
            
        case .Update:
            photoAlbumVC?.reloadItemsAtIndexPaths([indexPath!])
            
        case .Move:
            photoAlbumVC?.deleteItemsAtIndexPaths([indexPath!])
            photoAlbumVC?.insertItemsAtIndexPaths([newIndexPath!])
        }
        
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


