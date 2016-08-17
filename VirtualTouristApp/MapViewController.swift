//
//  MapViewController.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    
    //MARK: Properties
    var annotations = [MKPointAnnotation]()
    let locationManager = CLLocationManager()
    var currentPin: Pin? = nil
    
    lazy var sharedContext: NSManagedObjectContext = {
        // Get the stack
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        return stack.context
    }()
    
    @IBOutlet var mapView: MKMapView!
    
    @IBAction func editButton(sender: AnyObject) {
        //TODO: Create edit ability once Core Data is set up - will delete pins and connected photos from Core Data
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.delegate = self
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        uilpgr.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(uilpgr)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        //TODO: create method that will use pins already in core data to populate map OR do this in viewDidLoad?????
        // Use addMapLocations() method (change it first) to do this within an IF statement
        
        addMapLocations()
    }
    
    // gesture recognizer to accept long press to place a pin on the map
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        // Create new Pin object in Core Data managedObjectContext
        //TODO: Does the save to context work??? NOT YET!!
        let pin = Pin(annotation: annotation, context: sharedContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        
        do {
            try sharedContext.save()
            print("Saving context in handleLongPress")
        } catch {
            fatalError("Failure to save context in handleLongPress: \(error)")
        }
        
        mapView.addAnnotation(annotation)
        print("The tapped pin (from handleLongPress) has a latitude of \(pin.latitude!) and a longitude of \(pin.longitude!) with a title of \(pin.annotationTitle)")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        
        
        // Get location on app launch and set it as first location - save it in Core Data managedObjectContext
        //TODO: Does the save to context work???
        let pin = Pin(annotation: annotation, context: sharedContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        
        do {
            try sharedContext.save()
            print("Saving context in locationManager")
        } catch {
            fatalError("Failure to save context in locationManager: \(error)")
        }
        
        print("The locationManger pin (on app launch) has a latitude of \(pin.latitude!) and a longitude of \(pin.longitude!) with a title of \(pin.annotationTitle)")
        
        centerMapOnLocation(annotation, regionRadius: 1000.0)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print("Errors: " + error.localizedDescription)
    }
    
    //Centers the map on a coordinate (with lat and lon) with requisite radius
    func centerMapOnLocation(location: MKPointAnnotation, regionRadius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    //Test data to see if map is working
    func addMapLocations() {
        
        // Fetch request of managedObjectContext to get Pin instances from Core Data if they exist 
        // and add them to annotations array to populate map
        let request = NSFetchRequest(entityName: "Pin")
        do {
            let results = try sharedContext.executeFetchRequest(request) as! [Pin]
            if (results.count > 0) {
                print("Pin objects count: \(results.count) found in Core Data listed here:")
                for result in results {
                    print(result.latitude!)
                    let latitude = result.latitude as! Double
                    let longitude = result.longitude as! Double
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let title = result.annotationTitle
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    annotation.title = title
                    annotations.append(annotation)
                }
            } else {
                print("No Pin objects in Core Data in addMapLocations")
                return
            }
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        mapView.addAnnotations(annotations)
        
        centerMapOnLocation(annotations[0], regionRadius: 1000.0)

    }
    
    

    
    // MARK: - MKMapViewDelegate
    
    
    // "Right callout accessory view" created to NOT show - tap will be detected on the pin itself
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    // This method allows for a direct pin tap as opposed to a "right callout accessory view"
    // The segue to the PhotoAlbumVC is performed from the direct pin tap
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = (view.annotation?.coordinate)!
        let pin = Pin(annotation: annotation, context: sharedContext)
        
        print("The tapped pin (from mapView didSelectAnnotationView) has a latitude of \(annotation.coordinate.latitude) and a longitude of \(annotation.coordinate.longitude).")
        
        let request = NSFetchRequest(entityName: "Pin")
        do {
            let results = try sharedContext.executeFetchRequest(request) as! [Pin]
            print(results)
            if (results.count > 0) {
                for result in results {
                    if result.latitude == annotation.coordinate.latitude {
                        pin.latitude = annotation.coordinate.latitude
                        pin.longitude = annotation.coordinate.longitude
                    }
                }
                // Segue to PhotoAlbumVC with pin info being passed to tappedPin
                print("The fetched latitude is \(pin.latitude!) and the annotation latitude is \(annotation.coordinate.latitude)")
                performSegueWithIdentifier("showPhotoAlbumVC", sender: pin)
                
            } else {
                print("No Pin objects in Core Data on mapView select")
                return
            }
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPhotoAlbumVC" {
            let photoCollectionVC: PhotoAlbumViewController = segue.destinationViewController as! PhotoAlbumViewController
            photoCollectionVC.tappedPin = sender as? Pin
        }
    }
    
}




