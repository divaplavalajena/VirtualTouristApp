//
//  MapViewController.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    
    //MARK: Properties
    var annotations = [MKPointAnnotation]()
    let locationManager = CLLocationManager()
    
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
    }
    
    // gesture recognizer to accept long press to place a pin on the map
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        //set annotation latitude, longitude, and title on pin creation here
        FlickrClient.sharedInstance().latitude = annotation.coordinate.latitude
        FlickrClient.sharedInstance().longitude = annotation.coordinate.longitude
        FlickrClient.sharedInstance().annotationTitle = annotation.title
        
        mapView.addAnnotation(annotation)
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
        centerMapOnLocation(annotation, regionRadius: 1000.0)
        
        //set annotation latitude, longitude, and title on pin creation here
        FlickrClient.sharedInstance().latitude = annotation.coordinate.latitude
        FlickrClient.sharedInstance().longitude = annotation.coordinate.longitude
        FlickrClient.sharedInstance().annotationTitle = annotation.title
        print("The tapped pin has a latitude of \(FlickrClient.sharedInstance().latitude!) and a longitude of \(FlickrClient.sharedInstance().longitude!)")
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
        
        //Hard coded locations for testing on mapView
        let locations = [
            ["name" : "Apple Inc.",
                "latitude" : 37.33187,
                "longitude" : -122.02951,
                "mediaURL" : "http://www.apple.com"],
            ["name" : "BJ's Restaurant & Brewhouse",
                "latitude" : 37.33131,
                "longitude" : -122.03175,
                "mediaURL" : "http://www.bjsrestaurants.com"]
        ]
        
        for dictionary in locations {
            let latitude = CLLocationDegrees(dictionary["latitude"] as! Double)
            let longitude = CLLocationDegrees(dictionary["longitude"] as! Double)
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let name = dictionary["name"] as! String
            let mediaURL = dictionary["mediaURL"] as! String
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(name)"
            annotation.subtitle = mediaURL
            annotations.append(annotation)
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
        
        print("The tapped pin has a latitude of \(FlickrClient.sharedInstance().latitude!) and a longitude of \(FlickrClient.sharedInstance().longitude!)")
        
        performSegueWithIdentifier("showPhotoAlbumVC", sender: self)
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        
    }
    
}




