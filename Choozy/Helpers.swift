//
//  Helpers.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/2/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import MapKit
import SwiftyDrop
import Parse

func getLocationDictionary(location: CLLocation, completion: @escaping ([String: String]) -> ()){
    
    var locationInfo = ["country": "", "state": "", "city": "", "address": "", "subAddress": ""]
    
    CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
        
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        }
        
        if placemarks!.count > 0 || !placemarks!.isEmpty {
            
            guard let placemark = placemarks!.last else{
                return
            }
            
            if placemark.country != nil{locationInfo.updateValue(placemark.country!, forKey: "country")}
            if placemark.administrativeArea != nil{locationInfo.updateValue(placemark.administrativeArea!, forKey: "state")}
            if placemark.locality != nil{locationInfo.updateValue(placemark.locality!, forKey: "city")}
            if placemark.postalCode != nil{locationInfo.updateValue(placemark.postalCode!, forKey: "zip")}
            if placemark.thoroughfare != nil{locationInfo.updateValue(placemark.thoroughfare!, forKey: "address")}
            if placemark.subThoroughfare != nil{locationInfo.updateValue(placemark.subThoroughfare!, forKey: "subAddress")}
            
            completion(locationInfo)
        }
    })
}
//
//func getPostFromId(postId: String, completion: @escaping (Post) -> ()){
//    
//    let post = Post()
//    
//    let postQuery = PFQuery(className: "Post")
//    postQuery.includeKeys(["author"])
//    postQuery.whereKey("objectId", equalTo: postId)
//    postQuery.limit = 1
//    postQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
//        if let error = error{
//            print(error)
//            Drop.down(" : ( There was an error loading your post. Please try again.", state: Custom.error)
//        }else{
//            if !(objects?.isEmpty)!{
//                
//                for object in objects!{
//                    
//                    guard
//                        let id = object.objectId,
//                        let likes = object["likes"] as? Int,
//                        let views = object["views"] as? Int,
//                        let subAddress = object["subAddress"] as? String,
//                        let address = object["address"] as? String,
//                        let city = object["city"] as? String,
//                        let state = object["state"] as? String,
//                        let country = object["country"] as? String,
//                        let location = object["location"] as? PFGeoPoint,
//                        let author = object["author"] as? SpottyUser,
//                        let authorId = object["authorId"] as? String,
//                        let mediaUrl = object["mediaUrl"] as? String,
//                        let timeStamp = object.createdAt,
//                        let updatedTimeStamp = object.updatedAt
//                        else{
//                            return
//                    }
//                    
//                    
//                    post.objectId = id
//                    post.id = id
//                    post.likes = likes
//                    post.views = views
//                    post.subAddress = subAddress
//                    post.address = address
//                    post.city = city
//                    post.state = state
//                    post.country = country
//                    post.location = location
//                    post.author = author
//                    post.authorId = authorId
//                    post.mediaUrl = mediaUrl
//                    post.timeStamp = timeStamp
//                    post.updatedTimeStamp = updatedTimeStamp
//                    
//                }
//                
//                completion(post)
//            }
//        }
//    })
//}

func getDateStringFromDate(_ date: Date) -> String{
    var dateString = String()
    
    let currentTimeAsDate = Date(timeIntervalSince1970: NSDate().timeIntervalSince1970)
    let calendar = NSCalendar.current
    let dateFormatter = DateFormatter()
    
    let from = calendar.startOfDay(for: date)
    let to = calendar.startOfDay(for: currentTimeAsDate)
    let components = calendar.dateComponents([.day], from: from, to: to)
    let daysSincePost = components.day!
    
    if calendar.isDateInToday(date){ //Today - 2:12pm
        dateFormatter.dateFormat = "h:mm a"
        dateString = "Today - " + dateFormatter.string(from: date)
    }else if calendar.isDateInYesterday(date){ //Yesterday - 2:12pm
        dateFormatter.dateFormat = "h:mm a"
        dateString = "Yesterday - " + dateFormatter.string(from: date)
    }else if daysSincePost >= 2 && daysSincePost <= 7{ //Tuesday - 2:12pm
        dateFormatter.dateFormat = "EEEE - h:mm a"
        dateString = dateFormatter.string(from: date)
    }else if daysSincePost > 7{ //10.02.16
        dateFormatter.dateFormat = "MM.dd.yy"
        dateString = dateFormatter.string(from: date)
    }else{ //10.02.16
        dateFormatter.dateFormat = "MM.dd.yy - h:mm a"
        dateString = dateFormatter.string(from: date)
    }
    
    return dateString
}

func getAddressString(subAddress: String?, address: String?, city: String?, state: String?) -> String{
    var addressString = String()
    
    if subAddress != nil && address != nil && subAddress != "" && address != ""{
        addressString = subAddress! + " " + address!
    }else if city != nil && state != nil && city != "" && state != ""{
        addressString = city! + ", " + state!
    }else{
        addressString = "Unknown Location"
    }
    
    return addressString
}

func getStringFromLargeNumber(number: Int) -> String{
    let n = Double(number)
    
    if n > 1000000{
        return String(format:"%.2f", n/1000000) + "m"
    }else if n > 1000{
        return String(format:"%.2f", n/1000) + "k"
    }else{
        return String(format:"%.0f", n)
    }
    
}

func openCoordinateInMap(_ latitude: Double, longitude: Double){
    let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true] as [String : Any]
    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), addressDictionary: nil))
    mapItem.openInMaps(launchOptions: options)
}

func openURLInBrowser(url: String){
    UIApplication.shared.openURL(URL(string: url)!)
}

func getScreenshotOfView(view: UIView) -> UIImage{
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
    view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image!
}



func isUserLoggedIn() -> Bool{
    if ChoozyUser.current() != nil{
        if let firstName = ChoozyUser.current()?.firstName, let lastName = ChoozyUser.current()?.lastName, let profilePictureUrl = ChoozyUser.current()?.profilePictureUrl{
            return true
        }else{
            return false
        }
    }else{
        return false
    }
}

func onBoardingCheck() -> Bool {
    let onBoardCheck = false
    return onBoardCheck
}

//MARK: Drop Enum
enum Custom: DropStatable {
    
    case fetching
    case complete
    case empty
    case error
    
    var backgroundColor: UIColor? {
        //colors JT
//        let lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
        let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
        
        switch self {
//        case .fetching: return UIColor.blue.dark
        case .fetching: return blurple

//        case .complete: return UIColor.blue.light
        case .complete: return blurple

//        case .empty: return UIColor.watermelon.dark
        case .empty: return blurple

//        case .error: return UIColor.watermelon.dark
        case .error: return blurple

            
        }
    }
    var font: UIFont? {
        switch self {
        case .fetching, .complete, .empty, .error: return UIFont(name: "Avenir-Heavy", size: 16.0)
        }
    }
    var textColor: UIColor? {
        switch self {
        case .fetching, .complete, .empty, .error: return UIColor.white.flat
        }
    }
    var blurEffect: UIBlurEffect? {
        switch self {
        case .fetching, .complete, .empty, .error: return nil
        }
    }
}

//MARK: - App Defaults Struct
struct appDefaults{
    static let minimumSearchDistance: Float = 1.0
    static let maximumSearchDistance: Float = 300.0
    static let minimumReportedCount: Int = 5
}

////MARK: - App Config Struct
//struct configDefaults{
//    static let appVersion: String = "1.02"
//    static let parseApplicationId: String = "spotty_x_12345"
//    static let parseClientKey: String = "CLIENT_KEY"
//    static let parseServerUrl: String = "https://spotty-ios-production.herokuapp.com/parse"
//    static let appStoreUrl: String = "itms-apps://itunes.apple.com/app/id1194873530"
//}


