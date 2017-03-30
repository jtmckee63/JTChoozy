//
//  ViewController.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/1/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SwiftyDrop
import Parse
import AlamofireImage

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var postAnnotations:[PostAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Choozy"
        
        //Bar Button Items
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        settingsButton.contentMode = .scaleAspectFill
        settingsButton.setImage(UIImage(named: "settingsIcon"), for: .normal)
        settingsButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        let settingsBarButtonItem = UIBarButtonItem(customView: settingsButton)
        
        let selectionButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        selectionButton.contentMode = .scaleAspectFill
        selectionButton.setImage(UIImage(named: "zoomToLocationIcon"), for: .normal)
        selectionButton.addTarget(self, action: #selector(zoomToCurrentUserLocation), for: .touchUpInside)
        let selectionButtonBarButtonItem = UIBarButtonItem(customView: selectionButton)
        
        self.navigationItem.setLeftBarButtonItems([settingsBarButtonItem, selectionButtonBarButtonItem], animated: false)
        
        let newPostButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        newPostButton.contentMode = .scaleAspectFill
        newPostButton.setImage(UIImage(named: "cameraIcon"), for: .normal)
        newPostButton.addTarget(self, action: #selector(goToPostController), for: .touchUpInside)
        let newPostBarButtonItem = UIBarButtonItem(customView: newPostButton)
        
        let refreshButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        refreshButton.contentMode = .scaleAspectFill
        refreshButton.setImage(UIImage(named: "refreshIcon"), for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshAllData), for: .touchUpInside)
        let refreshBarButtonItem = UIBarButtonItem(customView: refreshButton)
        
        self.navigationItem.setRightBarButtonItems([refreshBarButtonItem, newPostBarButtonItem], animated: false)
        
        if !isUserLoggedIn(){
            logout()
        }else{
            refreshAllData()
        }
    }
    
    func logout(){
        ChoozyUser.logOut()
        self.showLoginController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ChoozyUser.current()?.fetchIfNeededInBackground()
    }

    func refreshAllData(){
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        askForLocationWhenInUsePermissions()
        askForPushNotificationsPermissions()
        locationManager.startUpdatingLocation()
        
        getUserLocation({(location) in
            Drop.down("Finding Posts...", state: Custom.fetching)
            self.retrievePosts(near: location)
        })
    }

    func retrievePosts(near location: PFGeoPoint){
       
        /* Remove Data from the mapView and
         any array that may hold data.
         */
      
        mapView.removeAnnotations(postAnnotations)
        postAnnotations.removeAll()

        /* Load Data from the Posts class name
         from parse where each object is within
         XX miles from the user's location. Then
         take each found object and add a
         post.
         */
        
        let postsQuery = PFQuery(className: "Post")
        postsQuery.includeKeys(["author"])
        postsQuery.whereKey("location", nearGeoPoint: location, withinMiles: Double(300))
        postsQuery.limit = 1000
        postsQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
            if let error = error{
                print(error)
                Drop.down(" There was an error finding posts. Please try again.", state: Custom.error)
            }else{
                if !(objects?.isEmpty)!{
                    
                    for object in objects!{
                        
                        guard
                            let id = object.objectId,
                            let likes = object["likes"] as? Int,
                            let views = object["views"] as? Int,
                            let subAddress = object["subAddress"] as? String,
                            let address = object["address"] as? String,
                            let city = object["city"] as? String,
                            let state = object["state"] as? String,
                            let country = object["country"] as? String,
                            let location = object["location"] as? PFGeoPoint,
                            let author = object["author"] as? ChoozyUser,
                            let authorId = object["authorId"] as? String,
                            let mediaUrl = object["mediaUrl"] as? String,
                            let placeId = object["placeId"] as? String,
                            let placeName = object["placeName"] as? String,
                            let timeStamp = object.createdAt,
                            let updatedTimeStamp = object.updatedAt
                        else{
                            continue
                        }
                        
                        let post = Post()
                        post.objectId = id
                        post.id = id
                        post.likes = likes
                        post.views = views
                        post.subAddress = subAddress
                        post.address = address
                        post.city = city
                        post.state = state
                        post.country = country
                        post.location = location
                        post.author = author
                        post.authorId = authorId
                        post.mediaUrl = mediaUrl
                        post.placeId = placeId
                        post.placeName = placeName
                        post.timeStamp = timeStamp
                        post.updatedTimeStamp = updatedTimeStamp
                        
                        self.addPostToMapView(post: post, showCallout: false, showZoom: false)
                    }
                    
                    let postAnnotationsCount = self.postAnnotations.count
                    
                    if postAnnotationsCount == 0 {
                        Drop.down(" Looks like there are no posts near you.", state: Custom.empty)
                    }else if postAnnotationsCount == 1{
                        Drop.down(" Found \(self.postAnnotations.count) post near you.", state: Custom.complete)
                    }else if postAnnotationsCount > 1{
                        Drop.down(" Found \(self.postAnnotations.count) posts near you.", state: Custom.complete)
                    }
                    
                }else{
                    
                    /* Find all spots, ignoring the
                     user's location.
                     */
                }
            }
        })
    }
    
    
    func addPostToMapView(post: Post, showCallout: Bool, showZoom: Bool){
        
        guard
            let id = post.id,
            let likes = post.likes,
            let views = post.views,
            let subAddress = post.subAddress,
            let address = post.address,
            let city = post.city,
            let state = post.state,
            let country = post.country,
            let location = post.location,
            let author = post.author,
            let authorId = post.authorId,
            let mediaUrl = post.mediaUrl,
            let placeId = post.placeId,
            let placeName = post.placeName,
            let timeStamp = post.timeStamp,
            let updatedTimeStamp = post.updatedTimeStamp
            else{
                print("found a nil something in addPostToMapView")
                return
        }
        
        let annotation = PostAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
        annotation.post.id = id
        annotation.post.likes = likes
        annotation.post.views = views
        annotation.post.subAddress = subAddress
        annotation.post.address = address
        annotation.post.city = city
        annotation.post.state = state
        annotation.post.country = country
        annotation.post.location = location
        annotation.post.author = author
        annotation.post.authorId = authorId
        annotation.post.mediaUrl = mediaUrl
        annotation.post.placeId = placeId
        annotation.post.placeName = placeName
        annotation.post.timeStamp = timeStamp
        annotation.post.updatedTimeStamp = updatedTimeStamp
        
        annotation.title = annotation.post.placeName
        annotation.subtitle = getDateStringFromDate(post.timeStamp!)
        
        postAnnotations.append(annotation)
        
        self.mapView.showAnnotations(self.postAnnotations, animated: true)
        
        /** showCallout and showZoom are only true when we are adding a postAnnotation from a new post
         *  (i.e. the user has taken a picture, and has posted it)
         *  for any other call to addPostToMapView, showCallout and showZoom should be false.
         */
        if showCallout{
            mapView.selectAnnotation(annotation, animated: true)
        }
        
        if showZoom{
            zoomToPost(post: annotation.post)
        }
    }
    
    
    //MARK: MapKit Delegate Methods
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
        if (view.annotation?.isKind(of: PostAnnotation.self))!{
            let postAnnotation = view.annotation as! PostAnnotation
            let post = postAnnotation.post
            
            self.showDetailController(post)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let postAnnotation = annotationView?.annotation as? PostAnnotation{
            
            let post = postAnnotation.post
            
            guard let mediaUrl = post.mediaUrl else{
                return nil
            }
            
            annotationView?.image = UIImage(named: "pin")
            
            let postImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            
            postImageView.af_setImage(withURL: URL(string: mediaUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: postImageView.frame.size), imageTransition: .crossDissolve(0.1))
            
            
            annotationView?.leftCalloutAccessoryView = postImageView
            annotationView?.canShowCallout = true
        }
        
        return annotationView
    }
    
    //MARK: - MapView Helpers
    func zoomToCurrentUserLocation(){
        
        let location = mapView.userLocation.coordinate
        let region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(location.latitude, location.longitude), MKCoordinateSpanMake(0.0125, 0.0125))
        
        mapView.setRegion(region, animated: true)
        
        //Show the My Location callout
        for annotation in mapView.annotations{
            if annotation.isKind(of: MKUserLocation.self){
                self.mapView.selectAnnotation(annotation, animated: true)
                break
            }
        }
    }
    
    func zoomToPost(post: Post){
        
        guard let latitude = post.location?.latitude, let longitude = post.location?.longitude else{
            return
        }
        
        let region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(latitude, longitude), MKCoordinateSpanMake(0.0001, 0.0001))
        mapView.setRegion(region, animated: true)
    }
    
    //MARK: - Navigation Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail"{
            
            let detailController: DetailController = segue.destination as! DetailController
            detailController.post = (sender as? Post)!
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    
    func goToPostController(){
        if isUserLoggedIn(){
            self.showPostController()
        }
    }
    
    //MARK: - CoreLocation Helpers
    func getUserLocation(_ completion: @escaping (PFGeoPoint) -> ()){
        PFGeoPoint.geoPointForCurrentLocation(inBackground: {(location: PFGeoPoint?, error: Error?) -> Void in
            if let error = error{
                let location = self.locationManager.getCurrentLocationCoordinates()
                completion(PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
            }else{
                if location != nil{
                    completion(location!)
                }else{
                    let location = self.locationManager.getCurrentLocationCoordinates()
                    completion(PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
                }
            }
        })
    }
    
    //MARK: - Permissions
    //TODO: - *** Permissions are a tricky subject. Research and figure out the best way to prompt for permissions. ***
    func askForLocationWhenInUsePermissions(){
        locationManager.requestWhenInUseAuthorization()
    }
    
    func askForPushNotificationsPermissions(){
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
    }
    

}
