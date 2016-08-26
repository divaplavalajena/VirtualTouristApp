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
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
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
    
    @IBOutlet var bottomButton: UIBarButtonItem!
    @IBAction func newCollectionButton(sender: AnyObject) {
        
        if selectedIndexes.isEmpty {
            // call to delete all photos from FRC and Core Data
            deleteAllPhotos()
        } else {
            // call to delete selected photos from FRC and Core Data
            deleteSelectedPhotos()
        }
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
        
        //load saved pins
        do {
            try fetchedResultsController.performFetch()
            print("FRC called on viewDidLoad to perform fetch")
        } catch {
            print("There was an error fetching on viewDidLoad of PhotoAlbumVC")
        }
        
        // Set bottom button text determined by selectedIndexes.count
        updateBottomButton()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
            loadPhotoAlbum()
        } else {
            //load saved photos at pin location saved in Core Data and accessed by the FRC
            self.photoAlbumVC.reloadData()
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        // lay out the collection view so that the cells take up 1/3 of the width with no space between
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        //2 - defines minimum spacing between horizontal items
        flowLayout.minimumLineSpacing = 0.0
        //3 - defines minimum spacing between vertical items
        flowLayout.minimumInteritemSpacing = 0.0
        
        let width = floor(self.photoAlbumVC.frame.size.width/3)
        flowLayout.itemSize = CGSize(width: width, height: width)
        
        photoAlbumVC.collectionViewLayout = flowLayout
        
    }
    
    
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
                    }
                })
            } else {
                print("The error is in the first Flickr method getting the page number. Error: \(error)")
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
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = photoAlbumVC.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        
        return cell
    }
    
    
    // MARK: - Configure Cell
    
     func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
     
         var photoImage = UIImage(named: "placeholderImageCamera-300px.png")
         
         let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
         
         // Set the Flickr Image
         if photo.imagePath == nil || photo.imagePath == "" {
             photoImage = UIImage(named: "placeholderImageCamera-300px.png")!
            
         } else if photo.imageData != nil {
             //Loads images from saved Core Data if picture content exists
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
                    photoImage = UIImage(data: data)!
                    
                    // save in Core Data
                    photo.imageData = data
                    self.saveToBothContexts()
                    
                    // update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = photoImage
                    }
                    
                }
                                                                        
             })
            
            dispatch_async(dispatch_get_main_queue()) {
                cell.taskToCancelifCellIsReused = task
            }
         }
         
        cell.imageView!.image = photoImage
        
        // If the cell is "selected" it's color panel is grayed out
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1.0
        }

    }
    
    
     func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("in collectionView(_:didSelectItemAtIndexPath)")
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        updateBottomButton()
     }
 
    // MARK: Save to Both Contexts function
    func saveToBothContexts() {
        // Save pin data to both contexts
        let stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
        stack.saveBothContexts()
    }
    
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
    

    
    // MARK: NSFetchedResultsController Methods
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageID", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pinData == %@", self.tappedPin!)
        print("This is the fetchedResultsController being created with the tappedPin.latitude: \(self.tappedPin.latitude!)")
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }
 
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the index paths into the three arrays.

    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?) {

        switch type {
            
        case .Insert:
            print("Insert an item")
            // Here we are noting that a new Photo instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We do expect Photo instances to change after they are created (if they are selected for deletion). But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
            //default:
            //break
        }
        
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        photoAlbumVC.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.photoAlbumVC.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoAlbumVC.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.photoAlbumVC.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

    // MARK: Button Helper methods
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Photos"
        } else {
            bottomButton.title = "Clear All Photos"
        }
    }
    
    func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        print("deleting all photos")
        
        // save deletions in Core Data
        saveToBothContexts()
        
        // reload photos for pin
        loadPhotoAlbum()
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
            print("deleting selected photos")
        }
        
        selectedIndexes.removeAll()
        
        // save deletions in Core Data
        saveToBothContexts()
    }


    
}



