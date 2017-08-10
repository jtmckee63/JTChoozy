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
import Alamofire
import AlamofireImage
import SwiftyJSON
import GooglePlaces
import DropDownMenuKit
import BTNavigationDropdownMenu

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var placeSearchBar: UISearchBar!


    
    let locationManager = CLLocationManager()
    var postAnnotations:[PostAnnotation] = []
    
    @IBOutlet weak var selectedCellLabel: UILabel!
    var menuView: BTNavigationDropdownMenu!
    
    @IBOutlet weak var bigButtonPost: UIButton!
    
    var searchBool = false
    //colors JT
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    var lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    var black: UIColor = UIColor.black
    
    //JT added for time feature
    var currentDate = Date()
    var formatter = DateFormatter()
    let calendar = NSCalendar.autoupdatingCurrent

    //JT onboard
    let userDefaults = UserDefaults.standard
    var tutorialCheck = false
    var logoutCheck = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let items = ["Eat", "Drink", "Play", "Post"]
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = black
        
        menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: "Dropdown Menu", items: items as [AnyObject])
        menuView.cellHeight = 50
        menuView.cellBackgroundColor = self.navigationController?.navigationBar.barTintColor
        menuView.cellSelectionColor = lightGreen
        menuView.shouldKeepSelectedCellColor = true
        menuView.cellTextLabelColor = UIColor.white
        menuView.cellTextLabelFont = UIFont(name: "Avenir-Heavy", size: 17)
        menuView.cellTextLabelAlignment = .center // .left // .Right // .Left
        menuView.arrowPadding = 15
        menuView.animationDuration = 0.5
        menuView.maskBackgroundColor = UIColor.black
        menuView.maskBackgroundOpacity = 0.3
        menuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
            print("Did select item at index: \(indexPath)")
            
            if indexPath == 0 {
                print("slected Eat")
                self.mapView.removeAnnotations(self.postAnnotations)

                let keyword = "Eat"
                self.placeSearchBar.text = ""
                self.searchForPlaces(for: keyword)
            }
            if indexPath == 1 {
                print("selected Drink")
                self.mapView.removeAnnotations(self.postAnnotations)

                let keyword = "Bars"
                self.placeSearchBar.text = ""

                self.searchForPlaces(for: keyword)
            }
            if indexPath == 2 {
                print("selected Play")
                self.mapView.removeAnnotations(self.postAnnotations)

                let keyword = "Entertainment"
                self.placeSearchBar.text = ""

                self.searchForPlaces(for: keyword)
            }
            if indexPath == 3 {
                self.placeSearchBar.text = ""
                self.removeSearchPlacesFromMapView()
                self.refreshAllData()
            }

        }
        
        self.navigationItem.titleView = menuView
        
        //Bar Button Items
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        settingsButton.contentMode = .scaleAspectFill
        settingsButton.setImage(UIImage(named: "person"), for: .normal)
        settingsButton.addTarget(self, action: #selector(goToProfileController), for: .touchUpInside)
        let settingsBarButtonItem = UIBarButtonItem(customView: settingsButton)
        
        let selectionButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        selectionButton.contentMode = .scaleAspectFill
        selectionButton.setImage(UIImage(named: "zoomToLocationIcon"), for: .normal)
        selectionButton.addTarget(self, action: #selector(zoomToCurrentUserLocation), for: .touchUpInside)
        let selectionButtonBarButtonItem = UIBarButtonItem(customView: selectionButton)
        
        self.navigationItem.setLeftBarButtonItems([settingsBarButtonItem, selectionButtonBarButtonItem], animated: false)
        
        let newPostButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        newPostButton.contentMode = .scaleAspectFill
        newPostButton.setImage(UIImage(named: "settingsIcon"), for: .normal)
        newPostButton.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
        let newPostBarButtonItem = UIBarButtonItem(customView: newPostButton)
        
        //JT Added for new big button post
        bigButtonPost.addTarget(self, action: #selector(goToPostController), for: .touchUpInside)
        
        let refreshButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        refreshButton.contentMode = .scaleAspectFill
        refreshButton.setImage(UIImage(named: "refreshIcon"), for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshAllData), for: .touchUpInside)
        let refreshBarButtonItem = UIBarButtonItem(customView: refreshButton)
        
        self.navigationItem.setRightBarButtonItems([refreshBarButtonItem, newPostBarButtonItem], animated: false)
        
        //Search Bar
        placeSearchBar.barTintColor = black
        placeSearchBar.placeholder = "Pizza, Beer, Fun, etc..."
        placeSearchBar.delegate = self
        //Gesture for Dismissing the Keyboard
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(gesture)
        
        if !isUserLoggedIn(){
            self.tutorialCheck = false
            logout()
        }else{
            refreshAllData()
            let alertController = UIAlertController(title: "Tutorial", message: "Would You Like To View The Choozy Tutorial?", preferredStyle: .alert)
            let dismissHandler = {
                (action: UIAlertAction!) in
                self.dismiss(animated: true, completion: nil)
                self.tutorialCheck = true
            }

            let onboard = UIAlertAction(title:"OK", style: .default, handler:  { action in self.performSegue(withIdentifier: "onboard", sender: self) } )
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: dismissHandler))

            alertController.addAction(onboard)
            print("THIS WOKRS FOR ONBOARDING __________---------------__________---------")
            
            if (tutorialCheck == false) {
                if (logoutCheck == true){
                    self.present(alertController, animated: true, completion: nil)
                }
            }

        }
    }
    
        //JT added
    override func viewDidAppear(_ animated: Bool) {
        //added JT
        super.viewDidAppear(animated)
    }
    //JT ended
    
    func logout(){
        ChoozyUser.logOut()
        self.logoutCheck = true
        self.showLoginController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ChoozyUser.current()?.fetchIfNeededInBackground()
    }

    func refreshAllData(){
        if userDefaults.bool(forKey: "onBoardingComplete") {
            self.tutorialCheck = true
        }
        self.mapView.removeAnnotations(self.postAnnotations)
        self.removeSearchPlacesFromMapView()
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
        
        //JT added for Time feature
        formatter.dateFormat = "yyyy-MM-dd"
        let dateResult = formatter.string(from: currentDate)
        
        
        let postsQuery = PFQuery(className: "Post")
        postsQuery.includeKeys(["author"])
        //og code 300
        postsQuery.whereKey("location", nearGeoPoint: location, withinMiles: Double(30))
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
                        
                        print(timeStamp)
                        let stamp = self.formatter.string(from: timeStamp)
                        print(stamp)
                        print(dateResult)
                        //JT added to cal the number of days between the current date and the post..to delete in background based on logic
                        let numOfDays = self.currentDate.daysBetweenDate(toDate: timeStamp)
                        print("THIS IS THE NUMBER OF DAYS",numOfDays)
                        if numOfDays > -2 {
                            print("THIS WORKS *******")
                            self.addPostToMapView(post: post, showCallout: false, showZoom: false)
                        }
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
        
//        annotation.blurplePinColor()
        
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
    
    var searchPlaceAnnotations = [SearchPlaceAnnotation]()
    func addSearchPlaceToMapView(searchPlace: SearchPlace){
        
        if let latitude = searchPlace.latitude, let longitude = searchPlace.longitude {
            
            let annotation = SearchPlaceAnnotation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            annotation.searchPlace = searchPlace
            annotation.title = searchPlace.name
            annotation.subtitle = searchPlace.address
            
            searchPlaceAnnotations.append(annotation)
            
            self.mapView.showAnnotations(self.searchPlaceAnnotations, animated: true)
        }
    }
    
    func removeSearchPlacesFromMapView(){
        self.mapView.removeAnnotations(searchPlaceAnnotations)
        searchPlaceAnnotations.removeAll()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBool = false
    }
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        searchBool = true
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchBool = true
    }
    func searchForPlaces(for keyword: String){
        
        removeSearchPlacesFromMapView()
        self.mapView.removeAnnotations(self.postAnnotations)

        //Google Places returns an error for spaces in the Request URL
        let trimmedKeyword = keyword.replacingOccurrences(of: " ", with: "")
        
        let apiKey = "AIzaSyAO54B6oPO_SQGxlMIGzC8e0Khj3Dsy_no"
        //JT change for disticntion between search and drop down
        var meters = ""
        if placeSearchBar.text == "" {
            meters = "3000"

        } else {
            meters = "10000"

        }
        
        print(meters)
        getUserLocation({(location) in
            
            let latitude = location.latitude
            let longitude = location.longitude
//            let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=\(meters)&type=restaurant&keyword=\(keyword)&key=\(apiKey)"
            let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=\(meters)&keyword=\(trimmedKeyword)&key=\(apiKey)"
            
            Alamofire.request(urlString, method: .get).validate().responseJSON { response in
                switch response.result {
                case .success(let value):
                    
                    let json = JSON(value)
              
                    for (_, json):(String, JSON) in json["results"] {
                        
                        var place = SearchPlace()
                        place.name = json["name"].string
                        place.latitude = json["geometry"]["location"]["lat"].double
                        place.longitude = json["geometry"]["location"]["lng"].double
                        place.id = json["place_id"].string
                        place.address = json["vicinity"].string
                        
                        self.addSearchPlaceToMapView(searchPlace: place)
                    }

                case .failure(let error):
                    print(error)
                }
            }
        })
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
    
    
    //MARK: MapKit Delegate Methods
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
        if (view.annotation?.isKind(of: PostAnnotation.self))!{
            //JT added for differnt annotation buttons
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
            
            //JT end
            //JT comment out cam code
//            self.showDetailController(post)
        }
        
        if (view.annotation?.isKind(of: SearchPlaceAnnotation.self))!{

            
            if control == view.leftCalloutAccessoryView {
                if let annotation = view.annotation {
                    // Unwrap the double-optional annotation.title property or
                    // name the destination "Unknown" if the annotation has no title
                    let destinationName = (annotation.title ?? nil) ?? "Unknown"
                    openMapsAppWithDirections(to: annotation.coordinate, destinationName: destinationName)
                }
            }
            if control == view.rightCalloutAccessoryView {
                let searchPlaceAnnotation = view.annotation as! SearchPlaceAnnotation
                let searchPlace = searchPlaceAnnotation.searchPlace
                if let placeId = searchPlace.id, let placeName = searchPlace.name {
                    self.showPlaceController(placeId, placeName: placeName)
                }
            }

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
            //JT comment cam code
//            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
//            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
//            
//            annotationView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure) as UIButton
            //JT Code -start-
            let smallSquare = CGSize(width: 30, height: 30)
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")

            let rightButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            rightButton.tintColor = UIColor.red
            rightButton.setBackgroundImage(UIImage(named: "ChoozyOut"), for: UIControlState())
            annotationView?.rightCalloutAccessoryView = rightButton
            //JT Code -start-
        }
        
        if let postAnnotation = annotationView?.annotation as? PostAnnotation{
            
            let post = postAnnotation.post
            
            //JT comment cam code
//            guard let mediaUrl = post.mediaUrl else{
//                return nil
//            }
//            
//            annotationView?.image = UIImage(named: "pin")
//            
//            let postImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//            
//            postImageView.af_setImage(withURL: URL(string: mediaUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: postImageView.frame.size), imageTransition: .crossDissolve(0.1))
//            
//            
//            annotationView?.leftCalloutAccessoryView = postImageView
            
            
            //JT Code -start-
            let smallSquare = CGSize(width: 30, height: 30)
            annotationView?.image = UIImage(named: "pin")


            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            button.setBackgroundImage(UIImage(named: "CarIcon"), for: UIControlState())
            annotationView?.leftCalloutAccessoryView = button
            annotationView?.canShowCallout = true
            //JT Code -end-

            //right button annotation
            
        }
        
        if let searchPlaceAnnotation = annotationView?.annotation as? SearchPlaceAnnotation{
            //JT comment cam code
            let searchPlace = searchPlaceAnnotation.searchPlace
//
//            guard let placeId = searchPlace.id else{
//                return nil
//            }
//
//            let postImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//            postImageView.layer.cornerRadius = postImageView.frame.width / 2
//            postImageView.clipsToBounds = true
//            
//            self.loadPhotoForPlace(with: placeId, completion: {(photo) in
//                postImageView.image = photo
//            })
//        
//            annotationView?.leftCalloutAccessoryView = postImageView
//            annotationView?.image = UIImage(named: "pin2")
//            annotationView?.canShowCallout = true
            //JT Code -start-
            let smallSquare = CGSize(width: 30, height: 30)
            
            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            button.setBackgroundImage(UIImage(named: "CarIcon"), for: UIControlState())
            annotationView?.leftCalloutAccessoryView = button
            annotationView?.image = UIImage(named: "pin2")
            annotationView?.canShowCallout = true
            //JT Code -end-

        }
        
        return annotationView
    }
    
    func loadPhotoForPlace(with id: String, completion: @escaping (UIImage) -> ()){
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: id) { (photos, error) -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                if let firstPhoto = photos?.results.first {
                    GMSPlacesClient.shared().loadPlacePhoto(firstPhoto, callback: { (photo, error) -> Void in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        } else {
                            completion(photo!)
                        }
                    })
                }
            }
        }
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
    
    //MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty{
            removeSearchPlacesFromMapView()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    
        if let keyword = searchBar.text {
            searchForPlaces(for: keyword)
        }
        
        dismissKeyboard()
    }
 
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    //MARK: - Navigation Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail"{
            let detailController: DetailController = segue.destination as! DetailController
            detailController.post = (sender as? Post)!
        }
        
        if segue.identifier == "places"{
            let placeController: PlaceController = segue.destination as! PlaceController
            placeController.place = sender as? (String, String)
        }
        if segue.identifier == "profile" {
            let profileController: ProfileController = segue.destination as! ProfileController
            profileController.user = (sender as? ChoozyUser)!
            
        }
        if segue.identifier == "settings" {
            let settingsController: SettingsController = segue.destination as! SettingsController
            settingsController.user = (sender as? ChoozyUser)!
            
        }

        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }
    
    
    func goToPostController(){
        if isUserLoggedIn(){
            placePost = false
            self.showPostController()
        }
    }
    func goToProfileController(){
        if isUserLoggedIn(){
            print("inside goToProfileController()")
            print(ChoozyUser.current()!)
            let user = ChoozyUser.current()
            print(user)
//            self.showProfileController(user!)
            self.performSegue(withIdentifier: "profile", sender: user)

        }
    }
    func goToSettings(){
        if isUserLoggedIn(){
            let user = ChoozyUser.current()
            self.performSegue(withIdentifier: "settings", sender: user)
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

struct SearchPlace {
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var id: String?
    var address: String?
}

extension Date {
    func daysBetweenDate(toDate: Date) -> Int{
        let components = Calendar.current.dateComponents([.day], from: self, to: toDate)
        return components.day ?? 0
    }
}
