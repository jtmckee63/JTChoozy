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
import DropDownMenuKit
import GooglePlaces
import GoogleMaps

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, DropDownMenuDelegate {
    
    @IBOutlet var mapView: MKMapView!
    
    
    let locationManager = CLLocationManager()
    var postAnnotations:[PostAnnotation] = []
    
    //DropDownMenuKit JT
    //DropDownMenuKit
    var titleView: DropDownTitleView!
    @IBOutlet var navigationBarMenu: DropDownMenu!
    @IBOutlet var toolbarMenu: DropDownMenu!
    
    //SearchBar JT
    var resultSearchController:UISearchController? = nil
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    //colors JT
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    var lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    var black: UIColor = UIColor.black
    
    //Post Check JT
    var postCheck = false
    //Added JT
    @IBOutlet weak var newPostBigButton: UIButton!
    
    //Added JT menu bar color
    var navigationBarAppearance = UINavigationBar.appearance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //SearchBar JT
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        //        searchBar.self = resultSearchController?.searchBar
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true

        //NavBar color JT
        navigationController?.navigationBar.barTintColor = UIColor.black
        
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: lightGreen]
        

        
        //DropDownMenuKit JT
        let title = prepareNavigationBarMenuTitleView()
        
        prepareNavigationBarMenu(title)
        prepareToolbarMenu()
        updateMenuContentOffsets()
        
        //Bar Button Items
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        settingsButton.contentMode = .scaleAspectFill
        settingsButton.setImage(UIImage(named: "settingsIcon"), for: .normal)
        settingsButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        let settingsBarButtonItem = UIBarButtonItem(customView: settingsButton)
        settingsButton.tintColor = UIColor.blue
        
        let selectionButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        selectionButton.contentMode = .scaleAspectFill
        selectionButton.setImage(UIImage(named: "zoomToLocationIcon"), for: .normal)
        selectionButton.addTarget(self, action: #selector(zoomToCurrentUserLocation), for: .touchUpInside)
        let selectionButtonBarButtonItem = UIBarButtonItem(customView: selectionButton)
        selectionButton.tintColor = lightGreen
        
        self.navigationItem.setLeftBarButtonItems([settingsBarButtonItem, selectionButtonBarButtonItem], animated: false)
        
        let newPostButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        newPostButton.contentMode = .scaleAspectFill
        newPostButton.setImage(UIImage(named: "cameraIcon"), for: .normal)
        newPostButton.addTarget(self, action: #selector(goToPostController), for: .touchUpInside)
        let newPostBarButtonItem = UIBarButtonItem(customView: newPostButton)
        newPostButton.tintColor = lightGreen
        
        //added for big post button JT
        newPostBigButton.addTarget(self, action: #selector(goToPostController), for: .touchUpInside)
        
        let refreshButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        refreshButton.contentMode = .scaleAspectFill
        refreshButton.setImage(UIImage(named: "refreshIcon"), for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshAllData), for: .touchUpInside)
        let refreshBarButtonItem = UIBarButtonItem(customView: refreshButton)
        
        self.navigationItem.setRightBarButtonItems([refreshBarButtonItem, newPostBarButtonItem], animated: false)
        refreshButton.tintColor = lightGreen
        
        if !isUserLoggedIn(){
            logout()
        }else{
            refreshAllData()
        }
    }
    //JT added
    override func viewDidAppear(_ animated: Bool) {
        //added JT
        navigationBarMenu.container = view
        toolbarMenu.container = view
        
        //added JT
        self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true);
    }
    //JT ended
    
    func logout(){
        ChoozyUser.logOut()
        self.showLoginController()
    }
    
    //added JT
    //annotations and adding click options
    func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destinationName name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name // Provide the name of the destination in the To: field
        mapItem.openInMaps(launchOptions: options)
    }
    //JT ended


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
        postCheck = false
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
            
            if control == view.leftCalloutAccessoryView {
                if let annotation = view.annotation {
                    // Unwrap the double-optional annotation.title property or
                    // name the destination "Unknown" if the annotation has no title
                    let destinationName = (annotation.title ?? nil) ?? "Unknown"
                    openMapsAppWithDirections(to: annotation.coordinate, destinationName: destinationName)
                }
            }
            
            if control == view.rightCalloutAccessoryView {
                let postAnnotation = view.annotation as! PostAnnotation
                let post = postAnnotation.post
            
                self.showDetailController(post)
            }
            
            
//            let postAnnotation = view.annotation as! PostAnnotation
//            let post = postAnnotation.post
//            
//            self.showDetailController(post)
            
        } else {
            //added for mklocal search JT
            if control == view.leftCalloutAccessoryView {
                if let annotation = view.annotation {
                    // Unwrap the double-optional annotation.title property or
                    // name the destination "Unknown" if the annotation has no title
                    let destinationName = (annotation.title ?? nil) ?? "Unknown"
                    openMapsAppWithDirections(to: annotation.coordinate, destinationName: destinationName)
                }
            }
            if control == view.rightCalloutAccessoryView {
            
                let myAnnotation = view.annotation as! MyAnnotation
                
                let myPlace = myAnnotation.place
                
                let loc = myAnnotation.coordinate
                
                var pN = myPlace.name
                let placeLat = loc.latitude
                let placeLong = loc.longitude
                
//                let nearbyPostQuery : PFQuery = PFQuery(className: "Post")
//                let location = self.locationManager.getCurrentLocationCoordinates()
                let placeLocal = PFGeoPoint(latitude: placeLat, longitude: placeLong)
                print(placeLocal)
                
            
                
                //JT TYMEREX
                let postsQuery = PFQuery(className: "Post")
                postsQuery.includeKeys(["author"])
                postsQuery.whereKey("location", nearGeoPoint: placeLocal, withinMiles: Double(300))
                postsQuery.limit = 1000
                postsQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
                    if !(objects?.isEmpty)! {
                        for object in objects!{
                            let placeID = object["placeId"] as? String
                            myPlace.id = placeID
                            print(placeID)
                            print(myPlace.id)

                        }
                        let post = Post()
//                        post.placeId = placeID
                        post.placeId = myPlace.id
                        
                        self.showPlaceController(post.placeId!, placeName: pN!)

                        
                    }
                })
                
//                post.id = postID
            
                print(myPlace)
            }
            
            
//            let postAnnotation = view.annotation as! PostAnnotation
//            let post = postAnnotation.post
//            
//            self.showDetailController(post)
            
        }

    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        //added JT
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if (pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            let smallSquare = CGSize(width: 30, height: 30)
            
            //left button annotation
            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            button.setBackgroundImage(UIImage(named: "CarIcon"), for: UIControlState())
            pinView?.leftCalloutAccessoryView = button
            
            //right button annotation
            pinView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure) as UIButton
            let rightButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            rightButton.tintColor = UIColor.red
            rightButton.setBackgroundImage(UIImage(named: "ChoozyOut"), for: UIControlState())
            pinView?.rightCalloutAccessoryView = rightButton
            
        }
        else
        {
            pinView!.annotation = annotation
        }
        //JT end
        
        var annotationView: MKAnnotationView?
        
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            let smallSquare = CGSize(width: 30, height: 30)

            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            button.setBackgroundImage(UIImage(named: "CarIcon"), for: UIControlState())
            pinView?.leftCalloutAccessoryView = button
//            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let postAnnotation = annotationView?.annotation as? PostAnnotation{
            
            let post = postAnnotation.post
            
//            guard let mediaUrl = post.mediaUrl else{
//                return nil
//            }
            let smallSquare = CGSize(width: 30, height: 30)
            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            button.setBackgroundImage(UIImage(named: "CarIcon"), for: UIControlState())
            annotationView?.leftCalloutAccessoryView = button
            annotationView?.image = UIImage(named: "pin")
            
            //right button annotation
            annotationView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure) as UIButton
            let rightButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            rightButton.tintColor = UIColor.red
            rightButton.setBackgroundImage(UIImage(named: "ChoozyOut"), for: UIControlState())
            annotationView?.rightCalloutAccessoryView = rightButton
            
//            let postImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//            
//            postImageView.af_setImage(withURL: URL(string: mediaUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: postImageView.frame.size), imageTransition: .crossDissolve(0.1))
            
            
//            annotationView?.leftCalloutAccessoryView = postImageView
            annotationView?.canShowCallout = true
        }
        
        //added JT
        if (postCheck == true) {
            return pinView
        } else {
            
            //return pinAnnotationView
            
            return annotationView
            
        }
        //comment out JT
//        return annotationView

        
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
    //search JT
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let locManager = CLLocationManager()
        var currentLocation = CLLocation()
        
        currentLocation = locManager.location!
        
        mapView.removeAnnotations(postAnnotations)
        self.mapView .removeAnnotations(self.mapView.annotations)
        
        self.searchBar.setShowsCancelButton(true, animated: true)
        self.searchBar.endEditing(true)
        postCheck = true
        
        let userLoction: CLLocation = currentLocation
        let latitude = userLoction.coordinate.latitude
        let longitude = userLoction.coordinate.longitude
        let latDelta: CLLocationDegrees = 1.0
        let lonDelta: CLLocationDegrees = 1.0
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        self.mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
        let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        
        // 8
        locationManager.stopUpdatingLocation()
        
        let request = MKLocalSearchRequest()
        
        let dirRequest = MKDirectionsRequest()
        
        request.naturalLanguageQuery = searchBar.text
        
        request.region = mapView.region
        
        //        request.region = MKCoordinateRegion(center: initialLocation.coordinate, span: span)
        request.region = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 120701, 120701)
        
        let search = MKLocalSearch(request: request)
        search.start
            {
                response, error in
                guard let response = response else {
                    print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                    return
                }
                
                for item in response.mapItems {
                    // Display the received items
                    print(item.name)
                    //                    self.mapView.addAnnotation(self.annotation)
                    self.addPinToMapView(item.name!, latitude: item.placemark.location!.coordinate.latitude, longitude: item.placemark.location!.coordinate.longitude)
                    self.postCheck = true
                }
        }
        
        
    }
    //search JT
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        // Clear any search criteria
        searchBar.text = ""
        
        // Dismiss the keyboard
        searchBar.resignFirstResponder()
        
        //remove annotations from search
        self.mapView .removeAnnotations(self.mapView.annotations)
        
        //post check
        postCheck = false
        
        //reload posts
        refreshAllData()
        
        
    }

    //DropDownMenuKit JT
    func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return min(statusBarSize.width, statusBarSize.height)
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
    
    //DropDownMenuKit JT -start-
    func prepareNavigationBarMenuTitleView() -> String {
        // Both title label and image view are fixed horizontally inside title
        // view, UIKit is responsible to center title view in the navigation bar.
        // We want to ensure the space between title and image remains constant,
        // even when title view is moved to remain centered (but never resized).
        titleView = DropDownTitleView(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        titleView.addTarget(self,
                            action: #selector(ViewController.willToggleNavigationBarMenu(_:)),
                            for: .touchUpInside)
        titleView.addTarget(self,
                            action: #selector(ViewController.didToggleNavigationBarMenu(_:)),
                            for: .valueChanged)
        titleView.titleLabel.textColor = UIColor.white
        
        titleView.title = "Choozy"
        navigationItem.titleView = titleView
        
        
        return titleView.title!
    }
    
    func prepareNavigationBarMenu(_ currentChoice: String) {
        navigationBarMenu = DropDownMenu(frame: view.bounds)
        navigationBarMenu.delegate = self
        
        let firstCell = DropDownMenuCell()
        
        firstCell.textLabel!.text = "Eat"
        firstCell.textLabel?.textAlignment = NSTextAlignment.center
        firstCell.backgroundColor = UIColor.black
        firstCell.textLabel!.textColor = UIColor.white
        firstCell.menuAction = #selector(ViewController.choose(_:))
        firstCell.menuTarget = self
        if currentChoice == "Eat" {
            firstCell.accessoryType = .checkmark
        }
        
        let secondCell = DropDownMenuCell()
        
        secondCell.textLabel!.text = "Drink"
        secondCell.textLabel?.textAlignment = NSTextAlignment.center
        secondCell.backgroundColor = UIColor.black
        secondCell.textLabel!.textColor = UIColor.white
        secondCell.menuAction = #selector(ViewController.choose(_:))
        secondCell.menuTarget = self
        if currentChoice == "Drink" {
            firstCell.accessoryType = .checkmark
        }
        
        let thirdCell = DropDownMenuCell()
        
        thirdCell.textLabel!.text = "Play"
        thirdCell.textLabel?.textAlignment = NSTextAlignment.center
        thirdCell.backgroundColor = UIColor.black
        thirdCell.textLabel!.textColor = UIColor.white
        thirdCell.menuAction = #selector(ViewController.choose(_:))
        thirdCell.menuTarget = self
        if currentChoice == "Play" {
            firstCell.accessoryType = .checkmark
        }
        
        let fourthCell = DropDownMenuCell()
        
        fourthCell.textLabel!.text = "Posts"
        fourthCell.textLabel?.textAlignment = NSTextAlignment.center
        fourthCell.backgroundColor = UIColor.black
        fourthCell.textLabel!.textColor = UIColor.white
        fourthCell.menuAction = #selector(ViewController.choose(_:))
        fourthCell.menuTarget = self
        if currentChoice == "Posts" {
            firstCell.accessoryType = .checkmark
        }
        
        navigationBarMenu.menuCells = [firstCell, secondCell, thirdCell, fourthCell]
        
        // If we set the container to the controller view, the value must be set
        // on the hidden content offset (not the visible one)
        navigationBarMenu.visibleContentOffset =
            navigationController!.navigationBar.frame.size.height + statusBarHeight()
        
        // For a simple gray overlay in background
        navigationBarMenu.backgroundView = UIView(frame: navigationBarMenu.bounds)
        navigationBarMenu.backgroundView!.backgroundColor = UIColor.black
        navigationBarMenu.backgroundAlpha = 0.7
    }
    
    func prepareToolbarMenu() {
        toolbarMenu = DropDownMenu(frame: view.bounds)
        toolbarMenu.delegate = self
        
        let selectCell = DropDownMenuCell()
        
        selectCell.textLabel!.text = "Select"
        selectCell.imageView!.image = UIImage(named: "Ionicons-ios-checkmark-outline")
        selectCell.showsCheckmark = false
        selectCell.menuAction = #selector(ViewController.select as (ViewController) -> () -> ())
        selectCell.menuTarget = self
        
        let sortKeys = ["Name", "Date", "Size"]
        let sortCell = DropDownMenuCell()
        let sortSwitcher = UISegmentedControl(items: sortKeys)
        
        sortSwitcher.selectedSegmentIndex = sortKeys.index(of: "Name")!
        sortSwitcher.addTarget(self, action: #selector(ViewController.sort(_:)), for: .valueChanged)
        
        sortCell.customView = sortSwitcher
        sortCell.textLabel!.text = "Sort"
        sortCell.imageView!.image = UIImage(named: "Ionicons-ios-search")
        sortCell.showsCheckmark = false
        
        toolbarMenu.menuCells = [selectCell, sortCell]
        toolbarMenu.direction = .up
        
        // For a simple gray overlay in background
        toolbarMenu.backgroundView = UIView(frame: toolbarMenu.bounds)
        toolbarMenu.backgroundView!.backgroundColor = UIColor.black
        toolbarMenu.backgroundAlpha = 0.7
    }
    
    func updateMenuContentOffsets() {
        navigationBarMenu.visibleContentOffset =
            navigationController!.navigationBar.frame.size.height + statusBarHeight()
        toolbarMenu.visibleContentOffset =
            navigationController!.toolbar.frame.size.height
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            // If we put this only in -viewDidLayoutSubviews, menu animation is
            // messed up when selecting an item
            self.updateMenuContentOffsets()
        }, completion: nil)
    }
    
    @IBAction func choose(_ sender: AnyObject) {
        titleView.title = (sender as! DropDownMenuCell).textLabel!.text
        print((sender as! DropDownMenuCell).textLabel!.text)
        //        refresh(location)
        self.mapView .removeAnnotations(self.mapView.annotations)
        
        let locManager = CLLocationManager()
        var currentLocation = CLLocation()
        
        currentLocation = locManager.location!
        
        let userLoction: CLLocation = currentLocation
        let latitude = userLoction.coordinate.latitude
        let longitude = userLoction.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.09
        let lonDelta: CLLocationDegrees = 0.09
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        self.mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
        let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        
        // 8
        locationManager.stopUpdatingLocation()
        
        let request = MKLocalSearchRequest()
        
        let dirRequest = MKDirectionsRequest()
        
        
        if titleView.title == "Drink" {
            request.naturalLanguageQuery = "Bar"
            postCheck = true
        }
        
        if titleView.title == "Eat" {
            request.naturalLanguageQuery = "Eat"
            postCheck = true
        }
        
        if titleView.title == "Play" {
            request.naturalLanguageQuery = "Entertainment"
            postCheck = true
        }
        
        if titleView.title == "Choice" {
            request.naturalLanguageQuery = "Venue"
        }
        
        if titleView.title == "Posts" {
            postCheck = false
            //reload posts
            refreshAllData()
        }
        //comment out to work ---not
        request.region = mapView.region
        
        //        request.region = MKCoordinateRegion(center: initialLocation.coordinate, span: span)
        request.region = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 120701, 120701)
        
        let search = MKLocalSearch(request: request)
        search.start
            {
                response, error in
                guard let response = response else {
                    print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                    return
                }
                
                for item in response.mapItems {
                    // Display the received items
                    print(item.name)
                    //                    self.mapView.addAnnotation(self.annotation)
                    self.addPinToMapView(item.name!, latitude: item.placemark.location!.coordinate.latitude, longitude: item.placemark.location!.coordinate.longitude)
                    
                }
        }
        
    }
    
    //added JT
    //map
    func addPinToMapView(_ title: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MyAnnotation(coordinate: location, title: title)
        
        let place = Place()
        place.name = title
        place.latitude = longitude
        place.longitude = longitude
        
        annotation.place = place
        
        mapView.addAnnotation(annotation)
        
    }
    //added JT
    //map
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        if locations.first != nil {
            
            // 7
            let userLoction: CLLocation = locations[0]
            let latitude = userLoction.coordinate.latitude
            let longitude = userLoction.coordinate.longitude
            let latDelta: CLLocationDegrees = 0.125
            let lonDelta: CLLocationDegrees = 0.125
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            self.mapView.setRegion(region, animated: true)
            self.mapView.showsUserLocation = true
            let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
            
            let sourcePlaceMark = MKPlacemark(coordinate: location, addressDictionary: nil)
            
            // 8
            locationManager.stopUpdatingLocation()
            
            let request = MKLocalSearchRequest()
            
            if titleView.title == "Drink" {
                request.naturalLanguageQuery = "Bar"
                postCheck = true
            }
            
            if titleView.title == "Eat" {
                request.naturalLanguageQuery = "Eat"
                postCheck = true
                
            }
            
            if titleView.title == "Play" {
                request.naturalLanguageQuery = "Entertainment"
                postCheck = true
                
            }
            
            if titleView.title == "Choice" {
                request.naturalLanguageQuery = "Entertainment"
                postCheck = true
                
            }
            
            request.naturalLanguageQuery = "Food and Drink"
            request.region = mapView.region
            
            //            request.region = MKCoordinateRegion(center: initialLocation.coordinate, span: span)
            request.region = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 120000, 120000)
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response else {
                    print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                    return
                }
                
                for item in response.mapItems {
                    // Display the received items
                    print(item.name)
                    //                    self.mapView.addAnnotation(self.annotation)
                    self.addPinToMapView(item.name!, latitude: item.placemark.location!.coordinate.latitude, longitude: item.placemark.location!.coordinate.longitude)
                    
                }
            }
            
        }
        
    }
    
    @IBAction func select() {
        print("Sent select action")
    }
    
    @IBAction func sort(_ sender: AnyObject) {
        print("Sent sort action")
    }
    
    @IBAction func showToolbarMenu() {
        if titleView.isUp {
            titleView.toggleMenu()
        }
        toolbarMenu.show()
    }
    
    @IBAction func willToggleNavigationBarMenu(_ sender: DropDownTitleView) {
        toolbarMenu.hide()
        
        if sender.isUp {
            navigationBarMenu.hide()
        }
        else {
            navigationBarMenu.show()
        }
    }
    
    @IBAction func didToggleNavigationBarMenu(_ sender: DropDownTitleView) {
        print("Sent did toggle navigation bar menu action")
        //        refresh(locationManager)
        
    }
    
    func didTapInDropDownMenuBackground(_ menu: DropDownMenu) {
        if menu == navigationBarMenu {
            titleView.toggleMenu()
        }
        else {
            menu.hide()
        }
    }
    //DropDownMenuKit JT -end-


}
