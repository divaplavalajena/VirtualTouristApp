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
    var editMode = Bool()
    
    lazy var sharedContext: NSManagedObjectContext = {
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        return stack.context
    }()
    
    @IBOutlet var deleteLabel: UILabel!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var mapView: MKMapView!
    
        
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing,animated:animated)
        if (self.isEditing) {
            //In Editing mode
            self.editButtonItem.title = "Done"
            toolbar.isHidden = false
            deleteLabel.isHidden = false
            editMode = true
        }
        else {
            //Not in editing mode
            self.editButtonItem.title = "Edit"
            toolbar.isHidden = true
            deleteLabel.isHidden = true
            editMode = false
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        editMode = false
        deleteLabel.isHidden = true
        toolbar.isHidden = true
        navigationItem.rightBarButtonItem = editButtonItem
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let locationAuthStatus = CLLocationManager.authorizationStatus()
        if locationAuthStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        //locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        uilpgr.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(uilpgr)

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // adds pins to map (if they are in Core Data)
        // also called when navigating back from PhotoAlbumVC
        // centers on location on map pin last loaded into the array via handleLongPress gesture recognizer
        addMapLocations()
    }
    
    func savePinInContexts(_ annotation: MKPointAnnotation) {
        //func -create pins and access save in CoreDataStack.saveBothContexts so both main and persisting contexts are saved
        
        let pinInfo = annotation
        
        let request: NSFetchRequest<NSFetchRequestResult> = Pin.fetchRequest()
        do {
            let results = try sharedContext.fetch(request) as! [Pin]
            if (results.count == 0) {
                print("No Pin objects in Core Data on savePinInContexts call.")
                // Create new Pin object in Core Data managedObjectContext
                _ = Pin(annotation: pinInfo, context: sharedContext)
                // Save pin data to both contexts
                let stack = (UIApplication.shared.delegate as! AppDelegate).stack
                stack.saveBothContexts()
                print("Pin data was saved to the contexts after fetch resturned results == 0: \(pinInfo.coordinate.latitude)")
                print("These are the results saved currently in Core Data (if results.count == 0): \(results)")
            }
            if (results.count > 0) {
                if results.contains( where: { Double($0.latitude!) == annotation.coordinate.latitude}) {
                    print("Not saving becuase latitude already exists in Core Data context: \(pinInfo.coordinate.latitude)")
                    return
                } else {
                    // Create new Pin object in Core Data managedObjectContext
                    _ = Pin(annotation: pinInfo, context: sharedContext)
                    // Save pin data to both contexts
                    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
                    stack.saveBothContexts()
                    print("Pin data was saved to the contexts after fetch didn't find it in results: \(pinInfo.coordinate.latitude)")
                    print("These are the results saved currently in Core Data (if results.count > 0): \(results)")
                    return
                }
            }
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
    }
    
    // gesture recognizer to accept long press to place a pin on the map
    func handleLongPress(_ gestureRecognizer : UIGestureRecognizer){
        
        if gestureRecognizer.state != .began { return }
        
        let touchPoint = gestureRecognizer.location(in: self.mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        mapView.addAnnotation(annotation)
        print("The tapped pin (from handleLongPress) has a latitude of \(annotation.coordinate.latitude) and a longitude of \(annotation.coordinate.longitude) with a title of \(annotation.title)")
        
        savePinInContexts(annotation)
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        print(center)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        
        print("The locationManger pin (on app launch) has a latitude of \(annotation.coordinate.latitude) and a longitude of \(annotation.coordinate.longitude) with a title of \(annotation.title)")
        
        centerMapOnLocation(annotation, regionRadius: 1000.0)
        
        savePinInContexts(annotation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Errors: " + error.localizedDescription)
    }
    
    //Centers the map on a coordinate (with lat and lon) with requisite radius
    func centerMapOnLocation(_ location: MKPointAnnotation, regionRadius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    //Test data to see if map is working
    func addMapLocations() {
        
        annotations.removeAll()
        
        // Fetch request of managedObjectContext to get Pin instances from Core Data if they exist 
        // and add them to annotations array to populate map
        let request: NSFetchRequest<NSFetchRequestResult> = Pin.fetchRequest()
        do {
            let results = try sharedContext.fetch(request) as! [Pin]
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
        
        centerMapOnLocation(annotations.last!, regionRadius: 1000.0)

    }
    
    

    
    // MARK: - MKMapViewDelegate

    // "Right callout accessory view" created to NOT show - tap will be detected on the pin itself
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    // This method allows for a direct pin tap as opposed to a "right callout accessory view"
    // The segue to the PhotoAlbumVC is performed from the direct pin tap
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = (view.annotation?.coordinate)!
        
        if editMode == false {
        
            self.mapView.deselectAnnotation(view.annotation, animated: true)
            
            let request: NSFetchRequest<NSFetchRequestResult> = Pin.fetchRequest()
            do {
                let results = try sharedContext.fetch(request) as! [Pin]
                print(results)
                if (results.count > 0) {
                    if results.contains(where: { Double($0.latitude!) == annotation.coordinate.latitude}) {
                        for result in results {
                            if Double(result.latitude!) == annotation.coordinate.latitude {
                                // Segue to PhotoAlbumVC with pin info being passed to tappedPin
                                print("The fetched latitude (from mapView didSelectAnnotationView) is \(result.latitude!) and the annotation latitude is \(annotation.coordinate.latitude)")
                                performSegue(withIdentifier: "showPhotoAlbumVC", sender: result)
                            }
                        }
                    }
                    
                } else {
                    print("No Pin objects in Core Data on mapView select")
                }
            } catch let error as NSError {
                print("Fetch failed: \(error.localizedDescription)")
            }
            
            
        } else {
            self.mapView.deselectAnnotation(view.annotation, animated: true)
            
            //editMode == true so delete tapped pins
            let request: NSFetchRequest<NSFetchRequestResult> = Pin.fetchRequest()
            do {
                let results = try sharedContext.fetch(request) as! [Pin]
                print(results)
                if (results.count > 0) {
                    self.mapView.removeAnnotation(view.annotation!)
                    
                    if results.contains(where: { Double($0.latitude!) == annotation.coordinate.latitude}) {
                        for result in results {
                            if Double(result.latitude!) == annotation.coordinate.latitude {
                                // remove pin from context and mapView, then save
                                let pin = result
                                sharedContext.delete(pin)
                                
                                // Save deleted pin data to both contexts
                                let stack = (UIApplication.shared.delegate as! AppDelegate).stack
                                stack.saveBothContexts()
                                print("removing annotation and deleting from Core Data")
                                
                            }
                        }
                    }
                } else {
                    print("No Pin objects in Core Data on mapView select")
                }
            } catch let error as NSError {
                print("Fetch failed: \(error.localizedDescription)")
            }
            
        }
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotoAlbumVC" {
            let photoCollectionVC: PhotoAlbumViewController = segue.destination as! PhotoAlbumViewController
            photoCollectionVC.tappedPin = sender as? Pin
        }
    }
    
}




