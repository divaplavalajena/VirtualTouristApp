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
    var session = URLSession.shared
    
    fileprivate func bboxString(_ latitude: Double?, longitude: Double?) -> String {
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
    func getPagesFromFlickrBySearch(_ latitude: Double?, longitude: Double?, completionHandlerForFlickrPages: @escaping (_ randomPageNumber: Int?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let methodParameters: [String : AnyObject] = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod as AnyObject,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey as AnyObject,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude, longitude: longitude) as AnyObject,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL as AnyObject,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat as AnyObject,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback as AnyObject
        ]
        
        /* 2. Make the request */
        taskForGETMethod(methodParameters) { (result, error) in
            
            /* 3. Send the desired value(s) to completion handler or print to console */
            func displayError(_ error: String) {
                print(error)
            }
            if let error = error {
                completionHandlerForFlickrPages(nil, error)
            } else {
            
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = result?[Constants.FlickrResponseKeys.Status] as? String , stat == Constants.FlickrResponseValues.OKStatus else {
                    displayError("Flickr API returned an error. See error code and message in \(result)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                if let photosDictionary = result?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] {
                    /* GUARD: Is "pages" key in the photosDictionary? */
                    if let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int {
                        // pick a random page!
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        completionHandlerForFlickrPages(randomPage, nil)
                        
                    } else {
                        completionHandlerForFlickrPages(nil, error)
                    }
                    
                } else {
                    //error if the parsing didn't provide good info to photosDictionary
                    completionHandlerForFlickrPages(nil, error)
                }
            }
        }
    }
    
    //Get images from Flickr to display in collection view
    func displayImagesFromFlickrBySearch(_ latitude: Double?, longitude: Double?, withPageNumber: Int, completionHandlerForFlickrImages: @escaping (_ photos: [[String: AnyObject]]?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let methodParameters: [String : AnyObject] = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod as AnyObject,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey as AnyObject,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude, longitude: longitude) as AnyObject,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL as AnyObject,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat as AnyObject,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback as AnyObject,
            Constants.FlickrParameterKeys.Page: withPageNumber,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.UsePerPage
        ]
        
        /* 2. Make the request */
        taskForGETMethod(methodParameters) { (result, error) in
            
            /* 3. Send the desired value(s) to completion handler or print to console */
            func displayError(_ error: String) {
                print(error)
            }
            if let error = error {
                completionHandlerForFlickrImages(nil, error)
            } else {
            
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = result?[Constants.FlickrResponseKeys.Status] as? String , stat == Constants.FlickrResponseValues.OKStatus else {
                    displayError("Flickr API returned an error. See error code and message in \(result)")
                    return
                }
                
                /* Is the "photos" key in our result? */
                if let photosDictionary = result?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] {
                    /* Is the "photo" key in photosDictionary? */
                    if let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] {
                        if photosArray.count == 0 {
                            displayError("No Photos Found. Search Again.")
                            return
                        } else {
                            //completion handler passes photosArray to ViewController calling for further processing...
                            completionHandlerForFlickrImages(photosArray, nil)
                        }
                        
                    } else {
                        //error if the parsing from the photosDictionary down to the photosArray did not work
                        completionHandlerForFlickrImages(nil, error)
                    }
                    
                } else {
                    //error if the parsing didn't provide good info to photosDictionary
                    completionHandlerForFlickrImages(nil, error)
                }
                
            }
        }
        
    }
    
    func taskForGETMethod(_ parameters: [String:AnyObject], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        /* 1. Set the parameters */
        var parameters = parameters

        
        /* 2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(url: flickrURLFromParameters(parameters))
        
        /* 4. Make the request */
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            func sendError(_ error: String) {
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
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
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
        }) 
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }

    
    
    // MARK: Helper for Creating a URL from Parameters
    fileprivate func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // given raw JSON, return a usable Foundation object
    fileprivate func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }


    func getFlickrImage(_ size: String, filePath: String, completionHandlerForImage: @escaping (_ imageData: Data?, _ error: NSError?) -> Void) -> URLSessionTask {
        
        /* 1. Set the parameters */
        // There are none...
        
        /* 2/3. Build the URL and configure the request */
        let baseURL = URL(string: filePath)!
        let url = baseURL.appendingPathComponent(size)
        let request = URLRequest(url: url)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForImage(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            completionHandlerForImage(data, nil)
        }) 
        
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
