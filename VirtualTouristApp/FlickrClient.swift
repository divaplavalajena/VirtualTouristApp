//
//  FlickrClient.swift
//  VirtualTouristApp
//
//  Created by Jena Grafton on 7/29/16.
//  Copyright © 2016 Bella Voce Productions. All rights reserved.
//

import Foundation

// MARK: - FlickrClient: NSObject

class FlickrClient : NSObject {
    
    // MARK: Properties
    // shared session
    var session = NSURLSession.sharedSession()
    
    //TODO: get these values from Core Data instead
    var latitude:Double?
    var longitude:Double?
    var annotationTitle: String?
    
    private func bboxString() -> String {
        // ensure bbox is bounded by minimum and maximums
        if let latitude = latitude, let longitude = longitude {
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    
    // MARK: Flickr API
    
    //Get a random page number of pages searched on Flickr
    func getPagesFromFlickrBySearch(completionHandlerForFlickrPages: (randomPageNumber: Int?, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let methodParameters: [String : AnyObject] = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        /* 2. Make the request */
        taskForGETMethod(methodParameters) { (result, error) in
            
            /* 3. Send the desired value(s) to completion handler or print to console */
            func displayError(error: String) {
                print(error)
            }
            if let error = error {
                completionHandlerForFlickrPages(randomPageNumber: nil, error: error)
            } else {
            
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = result[Constants.FlickrResponseKeys.Status] as? String where stat == Constants.FlickrResponseValues.OKStatus else {
                    displayError("Flickr API returned an error. See error code and message in \(result)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                if let photosDictionary = result[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] {
                    /* GUARD: Is "pages" key in the photosDictionary? */
                    if let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int {
                        // pick a random page!
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        completionHandlerForFlickrPages(randomPageNumber: randomPage, error: nil)
                        
                    } else {
                        completionHandlerForFlickrPages(randomPageNumber: nil, error: error)
                    }
                    
                } else {
                    //error if the parsing didn't provide good info to photosDictionary
                    completionHandlerForFlickrPages(randomPageNumber: nil, error: error)
                }
                
                //self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage)
            }
        }
    }
    
    //Get images from Flickr to display in collection view
    func displayImagesFromFlickrBySearch(withPageNumber: Int, completionHandlerForFlickrImages: (photos: [Photo]?, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let methodParameters: [String : AnyObject] = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Page: withPageNumber,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.UsePerPage
        ]
        
        /* 2. Make the request */
        taskForGETMethod(methodParameters) { (result, error) in
            
            /* 3. Send the desired value(s) to completion handler or print to console */
            func displayError(error: String) {
                print(error)
            }
            if let error = error {
                completionHandlerForFlickrImages(photos: nil, error: error)
            } else {
            
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = result[Constants.FlickrResponseKeys.Status] as? String where stat == Constants.FlickrResponseValues.OKStatus else {
                    displayError("Flickr API returned an error. See error code and message in \(result)")
                    return
                }
                
                /* Is the "photos" key in our result? */
                if let photosDictionary = result[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] {
                    /* Is the "photo" key in photosDictionary? */
                    if let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] {
                        if photosArray.count == 0 {
                            displayError("No Photos Found. Search Again.")
                            return
                        } else {
                            let photos = Photo.photosFromResults(photosArray)
                            completionHandlerForFlickrImages(photos: photos, error: nil)
                        }
                        
                    } else {
                        //error if the parsing from the photosDictionary down to the photosArray did not work
                        completionHandlerForFlickrImages(photos: nil, error: error)
                    }
                    
                } else {
                    //error if the parsing didn't provide good info to photosDictionary
                    completionHandlerForFlickrImages(photos: nil, error: error)
                }
                
            }
        }
        
    }
    
    func taskForGETMethod(parameters: [String:AnyObject], completionHandlerForGET: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        var parameters = parameters

        
        /* 2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(URL: flickrURLFromParameters(parameters))
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }

    
    
    // MARK: Helper for Creating a URL from Parameters
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }


    func getFlickrImage(size: String, filePath: String, completionHandlerForImage: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {
        
        /* 1. Set the parameters */
        // There are none...
        
        /* 2/3. Build the URL and configure the request */
        let baseURL = NSURL(string: filePath)!
        let url = baseURL.URLByAppendingPathComponent(size)
        let request = NSURLRequest(URL: url)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForImage(imageData: nil, error: NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            completionHandlerForImage(imageData: data, error: nil)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }

    
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    
}