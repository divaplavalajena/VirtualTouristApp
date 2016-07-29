//
//  MapViewController.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    //Properties:
    var longitude: Double = 0.0
    var latitude: Double = 0.0
    
    var annotations = [MKPointAnnotation]()
    
    
    @IBOutlet var mapView: MKMapView!
    
    @IBAction func editButton(sender: AnyObject) {
        //TODO: complete edit button code on first page
    }
    
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        //TODO: set annotation title on pin creation here
        
        latitude = annotation.coordinate.latitude
        longitude = annotation.coordinate.longitude
        
        mapView.addAnnotation(annotation)
    }
    
    func centerMapOnLocation(location: MKPointAnnotation, regionRadius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.delegate = self
        
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
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        uilpgr.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(uilpgr)
        
        centerMapOnLocation(annotations[0], regionRadius: 1000.0)
    }
    
    override func viewWillAppear(animated: Bool) {
        //TODO: create method that will use pins already in core data to populate map
    }
    
    // MARK: - MKMapViewDelegate
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
            //pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let app = UIApplication.sharedApplication()
            if let toOpen = view.annotation?.subtitle! {
                app.openURL(NSURL(string: toOpen)!)
                print("The tapped pin has a latitude of \(latitude) and a longitude of \(longitude)")
            }
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        /*
         guard let annotation = view.annotation else { /* no annotation */ return }
         let latitude = annotation.coordinate.latitude
         let longitude = annotation.coordinate.longitude
         let title = annotation.title
         */
        
        /*
         let storyboard = UIStoryboard (name: "Main", bundle: nil)
         let photoAlbumVC = storyboard.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
         photoAlbumVC.latitudeP = latitude
         photoAlbumVC.longitudeP = longitude
         presentViewController(photoAlbumVC, animated: true, completion: nil)
         */
        
        performSegueWithIdentifier("showPhotoAlbumVC", sender: self)
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPhotoAlbumVC" {
            let controller = segue.destinationViewController as! PhotoAlbumViewController
            controller.latitudeP = latitude
            controller.longitudeP = longitude
        }
    }
    
}




