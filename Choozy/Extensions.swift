//
//  Extensions.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/2/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MobileCoreServices
import MediaPlayer
import SCLAlertView

var specPlace: (String, String)?

extension UIView {
    
    func circleWithBorder(_ color: UIColor, width: CGFloat){
        self.layer.cornerRadius = self.bounds.width / 2
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
    
    func applyGradient(topColor: UIColor, bottomColor: UIColor) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = self.bounds
        
        let zPosition = UInt32(self.layer.zPosition)
        
        self.layer.insertSublayer(gradientLayer, at: zPosition)
    }
    
    func applyShadow(color: UIColor, opacity: CGFloat, radius: CGFloat){
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = Float(opacity)
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = radius
    }
    
    func fadeOut(){
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0.0
        })
    }
    
    func fadeOutAndRemove(){
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0.0
        }, completion: {(_) in
            self.removeFromSuperview()
        })
    }
    
    func fadeOutAndRemove(time: Double){
        UIView.animate(withDuration: time, animations: {
            self.alpha = 0.0
        }, completion: {(_) in
            self.removeFromSuperview()
        })
    }
    
    func fadeIn(){
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1.0
        })
    }
    
    func fadeTo(alpha: CGFloat){
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = alpha
        })
    }
}

let invalidWords = ["fuck", "shit", "damn", "sex", "penis", "vagina", "cunt", "pussy", "dick", "bitch"]
extension String {
    
    func isEmpty() -> Bool{
        
        if self.replacingOccurrences(of: " ", with: "") == ""{
            return true
        }else{
            return false
        }
    }
    
    func containsInvalidCharacters() -> Bool{
        
        var invalid = Bool()
        
        for word in invalidWords{
            if self.lowercased().contains(word){
                invalid = true
            }
        }
        
        return invalid
    }
}

/** This extension of UIImageView provides a basic Caching of
 *  images, profiled there is a urlString to that points to an
 *  image hosted elsewhere. This is remaining in code as a backup to
 *  AlamoFireImage.
 */
let mediaCache: NSCache<NSString, UIImage> = NSCache()
extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(_ urlString: String){
        
        //Set Image as Blank so they are not displayed incorrectly when reused.
        self.image = nil
        
        //Check Cache for Images First.
        if let cachedImage = mediaCache.object(forKey: urlString as NSString){
            self.image = cachedImage
            self.fadeIn()
            return
        }
        
        //Otherwise, download a new image.
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            
            if error != nil{
                print(error)
                return
            }
            
            DispatchQueue.main.async(execute: {
                if let downloadedImage = UIImage(data: data!){
                    mediaCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = downloadedImage
                    self.fadeIn()
                }
            })
        }).resume()
    }
    
    func loadAndCircleImageUsingCacheWithUrlString(_ urlString: String, color: UIColor, width: CGFloat){
        
        //Set Image as Blank so they are not displayed incorrectly when reused.
        self.image = nil
        
        //Check Cache for Images First.
        if let cachedImage = mediaCache.object(forKey: urlString as NSString){
            self.image = cachedImage
            self.fadeIn()
            self.circleWithBorder(color, width: width)
            return
        }
        
        //Otherwise, download a new image.
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            
            if error != nil{
                print(error)
                return
            }
            
            DispatchQueue.main.async(execute: {
                if let downloadedImage = UIImage(data: data!){
                    mediaCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = downloadedImage
                    self.fadeIn()
                    self.circleWithBorder(color, width: width)
                }
            })
        }).resume()
    }
    
    func loadThumbnailImageForVideo(_ urlString: String){
        let asset = AVURLAsset(url: URL(string: urlString)!)
        var videoLength = asset.duration
        videoLength.value = min(videoLength.value, 2)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        
        do {
            let cgThumbnailImage = try imageGenerator.copyCGImage(at: videoLength, actualTime: nil)
            DispatchQueue.main.async(execute: {
                let thumbnailImage = UIImage(cgImage: cgThumbnailImage)
                self.image = thumbnailImage
                self.fadeIn()
            })
            
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
        }
    }
    
    func loadAndCircleThumbnailImageForVideo(_ urlString: String, color: UIColor, width: CGFloat){
        let asset = AVURLAsset(url: URL(string: urlString)!)
        var videoLength = asset.duration
        videoLength.value = min(videoLength.value, 2)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        do {
            let cgThumbnailImage = try imageGenerator.copyCGImage(at: videoLength, actualTime: nil)
            
            DispatchQueue.main.async(execute: {
                let thumbnailImage = UIImage(cgImage: cgThumbnailImage)
                self.image = thumbnailImage
                self.fadeIn()
                self.circleWithBorder(color, width: width)
            })
            
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
        }
    }
}

extension UIColor{
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat){
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1.0)
    }
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat){
        self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
    
    struct watermelon{
        static let dark = UIColor(r: 217, g: 84, b: 89)
        static let flat = UIColor(r: 239, g: 113, b: 122)
    }
    
    struct mint{
        static let dark = UIColor(r: 22, g: 160, b: 133)
        static let flat = UIColor(r: 26, g: 187, b: 155)
    }
    
    struct blue{
        static let extraDark = UIColor(r: 35, g: 93, b: 130)
        static let dark = UIColor(r: 41, g: 128, b: 185)
        static let flat = UIColor(r: 52, g: 152, b: 219)
        static let light = UIColor(r: 100, g: 181, b: 236)
    }
    
    struct purple{
        
        static let ultraDark = UIColor(r: 74, g: 62, b: 117)
        static let dark = UIColor(r: 91, g: 72, b: 162)
        static let flat = UIColor(r: 116, g: 94, b: 197)
        static let light = UIColor(r: 150, g: 130, b: 226)
        
        struct hex{
            static let flat: UInt = 0x745ec5
        }
    }
    
    struct orange{
        static let dark = UIColor(r: 211, g: 84, b: 0)
        static let flat = UIColor(r: 230, g: 126, b: 34)
    }
    
    struct green{
        static let dark = UIColor(r: 39, g: 174, b: 96)
        static let flat = UIColor(r: 46, g: 204, b: 113)
    }
    
    struct white{
        static let dark = UIColor(r: 189, g: 195, b: 199)
        static let flat = UIColor(r: 236, g: 240, b: 241)
        static let pure = UIColor(r: 255, g: 255, b: 255)
    }
    
    struct black{
        static let dark = UIColor(r: 38, g: 38, b: 38)
        static let flat = UIColor(r: 43, g: 43, b: 43)
        static let ultraDark = UIColor(r: 20, g: 20, b: 20)
        static let pure = UIColor(r: 0, g: 0, b: 0)
    }
    
    func randomFlatColor() -> UIColor{
        let randomColor = arc4random_uniform(6)
        var color = UIColor()
        
        switch randomColor{
        case 0: color = watermelon.flat
        case 1: color = mint.flat
        case 2: color = blue.flat
        case 3: color = purple.flat
        case 4: color = orange.flat
        case 5: color = green.flat
        default: color = purple.flat
        }
        
        return color
    }
    
    func randomDarkColor() -> UIColor{
        let randomColor = arc4random_uniform(6)
        var color = UIColor()
        
        switch randomColor{
        case 0: color = watermelon.dark
        case 1: color = mint.dark
        case 2: color = blue.dark
        case 3: color = purple.dark
        case 4: color = orange.dark
        case 5: color = green.dark
        default: color = purple.dark
        }
        
        return color
    }
    
    func randomColor() -> UIColor{
        let randomColor = arc4random_uniform(12)
        var color = UIColor()
        
        switch randomColor{
        case 0: color = watermelon.dark
        case 1: color = mint.dark
        case 2: color = blue.dark
        case 3: color = purple.dark
        case 4: color = orange.dark
        case 5: color = green.dark
        case 6: color = watermelon.flat
        case 7: color = mint.flat
        case 8: color = blue.flat
        case 9: color = purple.flat
        case 10: color = orange.flat
        case 11: color = green.flat
        default: color = purple.dark
        }
        
        return color
    }
    
    func randomColorScheme() -> (UIColor, UIColor){
        let randomColor = arc4random_uniform(6)
        var dark = UIColor()
        var flat = UIColor()
        
        switch randomColor{
        case 0: dark = watermelon.dark; flat = watermelon.flat
        case 1: dark = mint.dark; flat = mint.flat
        case 2: dark = blue.dark; flat = blue.flat
        case 3: dark = purple.dark; flat = purple.flat
        case 4: dark = orange.dark; flat = orange.flat
        case 5: dark = green.dark; flat = green.flat
        default: dark = mint.dark; flat = purple.flat
        }
        
        return (dark, flat)
    }
    
}

extension UIViewController{
    
    func showAlert(_ title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlertWithURL(_ title: String, message: String, urlMessage: String, URL: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: { action in }))
        alert.addAction(UIAlertAction(title: urlMessage, style: UIAlertActionStyle.cancel, handler: { action in
            let settingsUrl = Foundation.URL(string: URL)
            if let url = settingsUrl {
                UIApplication.shared.openURL(url)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showSCLAlert(_ title: String, message: String, image: UIImage){
        let alertView = SCLAlertView()
        alertView.showTitle(title, subTitle: message, style: .info, closeButtonTitle: "Okay", duration: 0.0, colorStyle: 0xEF717A, colorTextButton: 0xECF0F1, circleIconImage: image, animationStyle: .leftToRight)
    }
    
    func showSCLAlertWithURL(_ title: String, message: String, image: UIImage, urlMessage: String, URL: String){
        let alertView = SCLAlertView()
        alertView.addButton(urlMessage) {
            let settingsUrl = Foundation.URL(string: URL)
            if let url = settingsUrl {
                UIApplication.shared.openURL(url)
            }
        }
        alertView.showTitle(title, subTitle: message, style: .info, closeButtonTitle: "Okay", duration: 0.0, colorStyle: 0xEF717A, colorTextButton: 0xECF0F1, circleIconImage: image, animationStyle: .leftToRight)
    }
    
    func showPostController(){
//        
//        //Remove the Observer for Push Notifications
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "handlePushNotification"), object: nil)
//        
//        //Add the Observer for Force Touch Shortcuts
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "addPostFromShortcut"), object: nil)
//        
        let postController = NewPostController()
        self.present(postController, animated: true, completion: nil)
    }
    func exPlacePoster(_ placeId: String, placeName: String) {
        let thePlace = Place()

        let postController = NewPostController()
        thePlace.id = placeId
        thePlace.name = placeName
        specPlace = (placeId, placeName)
        print(placeId)
        print(placeName)
        
        self.present(postController, animated: true, completion: nil)
//        self.show(postController, sender: specPlace)

    }

    
    //MARK: - Segue Navigations
    func showLoginController(){
        self.performSegue(withIdentifier: "login", sender: nil)
        print("GO")
    }
    
    func showDetailController(_ post: Post){
        if post.mediaUrl != nil{
            self.performSegue(withIdentifier: "detail", sender: post)
        }else{
            print("failed to go to DetailController")
        }
    }
    
    func showSettingsController(){
        
        //Remove the Observer for Push Notifications
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "handlePushNotification"), object: nil)
        
        //Add the Observer for Force Touch Shortcuts
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "addPostFromShortcut"), object: nil)
        
        self.performSegue(withIdentifier: "settings", sender: nil)
    }
    
    func showLicensesController(){
        self.performSegue(withIdentifier: "licenses", sender: nil)
    }
    
    func showProfileController(_ user: ChoozyUser){
        self.performSegue(withIdentifier: "profile", sender: user)
    }
    
    func showPlaceController(_ placeId: String, placeName: String){
        let place = (placeId, placeName)
        self.performSegue(withIdentifier: "places", sender: place)
    }
    
    func showDetailImageController(_ mediaUrl: String){
        self.performSegue(withIdentifier: "showDetailImage", sender: mediaUrl)
    }
    
    func dismissViewController(){
        self.dismiss(animated: true, completion: nil)
    }
    //Added for onboard
    func showOnboardController(){
        self.performSegue(withIdentifier: "onboard", sender: self)
    }
    
    func pop(){
        self.navigationController?.popViewController(animated: true)
    }
}

extension UserDefaults{
    
    func getSearchDistance() -> Double{
        var searchDistance = Double()
        if let d = self.value(forKey: "searchDistance") as? Double{
            searchDistance = d
        }else{
            //Set a Default Value
            //originally sete to 100.0
            searchDistance = 10.0
            setSearchDistance(distance: searchDistance)
        }
        return searchDistance
    }
    
    func setSearchDistance(distance: Double){
        self.setValue(distance, forKey: "searchDistance")
    }
    
    func getLoadCount() -> Int{
        var loadCount = Int()
        if let d = self.value(forKey: "loadCount") as? Int{
            loadCount = d
        }else{
            //Set a Default Value
            loadCount = 0
            setLoadCount(loadCount: loadCount)
        }
        return loadCount
    }
    
    func setLoadCount(loadCount: Int){
        self.setValue(loadCount, forKey: "loadCount")
    }
    
    func getHasRated() -> Bool{
        var hasRated = Bool()
        if let d = self.value(forKey: "hasRated") as? Bool{
            hasRated = d
        }else{
            //Set a Default Value
            hasRated = false
            self.setValue(hasRated, forKey: "hasRated")
        }
        
        return hasRated
    }
    
    func setHasRated(hasRated: Bool){
        self.setValue(hasRated, forKey: "hasRated")
    }
    
}

extension CLLocationManager{
    
    func getCurrentLocationCoordinates() -> (latitude: Double, longitude: Double){
        var latitude = Double()
        var longitude = Double()
        
        if let lat = self.location?.coordinate.latitude, let long = self.location?.coordinate.longitude{
            latitude = lat
            longitude = long
        }
        
        return (latitude, longitude)
    }
    
    func getCurrentLocationDictionary(_ completion: @escaping ([String: String]) -> ()){
        
        var locationInfo = ["latitude": String(), "longitude": String(), "country": String(), "state": String(), "city": String(), "zip": String(), "address": String(), "subAddress": String()]
        if let lat = self.location?.coordinate.latitude, let long = self.location?.coordinate.longitude{
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: long), completionHandler: {(placemarks, error) -> Void in
                
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                
                if placemarks!.count > 0 || !placemarks!.isEmpty {
                    
                    guard let placemark = placemarks!.last else{
                        return
                    }
                    
                    locationInfo.updateValue("\(lat)", forKey: "latitude")
                    locationInfo.updateValue("\(long)", forKey: "longitude")
                    if placemark.country != nil{locationInfo.updateValue(placemark.country!, forKey: "country")}
                    if placemark.administrativeArea != nil{locationInfo.updateValue(placemark.administrativeArea!, forKey: "state")}
                    if placemark.locality != nil{locationInfo.updateValue(placemark.locality!, forKey: "city")}
                    if placemark.postalCode != nil{locationInfo.updateValue(placemark.postalCode!, forKey: "zip")}
                    if placemark.thoroughfare != nil{locationInfo.updateValue(placemark.thoroughfare!, forKey: "address")}
                    if placemark.subThoroughfare != nil{locationInfo.updateValue(placemark.subThoroughfare!, forKey: "subAddress")}
                    
                    //Return
                    completion(locationInfo)
                }
            })
        }
    }
}



