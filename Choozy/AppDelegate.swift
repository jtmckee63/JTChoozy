//
//  AppDelegate.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/1/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import FBSDKCoreKit
import Parse
import ParseFacebookUtilsV4
import SwiftyDrop
import GooglePlaces
import paper_onboarding
var placePost = false


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
    //colors JT
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    var lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    var black: UIColor = UIColor.black
    //JT onboard
    let userDefaults = UserDefaults.standard
    var tutorialCheck = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //Navigation Controller
        let navigationItem = UINavigationItem()
        let navigationBarAppearance = UINavigationBar.appearance()
//        navigationBarAppearance.barTintColor = UIColor.blue.flat
        navigationBarAppearance.barTintColor = blurple

        navigationBarAppearance.barStyle = UIBarStyle.black
        navigationBarAppearance.tintColor = UIColor.white.pure
        navigationBarAppearance.isTranslucent = false
        navigationBarAppearance.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white.pure, NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 16.0)!]
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style: .plain, target: nil, action: nil)
        
        //Configure FBSDK -- used for Login && Ads
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //Register PFUser sublass.
        ChoozyUser.registerSubclass()
        
        //Initialize Parse Configuration.
        let configuration = ParseClientConfiguration{
            $0.applicationId = "choozy"
            $0.clientKey = "choozy"
            $0.server = "https://choozy.herokuapp.com/parse"
        }
        
        //Initialize Parse
        Parse.initialize(with: configuration)
        
        
        //Intialize PFFacebookUtils
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        
        //Google Places
        GMSPlacesClient.provideAPIKey("AIzaSyAO54B6oPO_SQGxlMIGzC8e0Khj3Dsy_no")

        return true
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        saveInstallation(deviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        if let id = userInfo["postId"] as? String {
            if let notificationString = userInfo["notificationString"] as? String{
                
                let applicationState = application.applicationState.rawValue
                
                if applicationState != 0 { // !state.active
                    let navigationController = application.windows[0].rootViewController as! UINavigationController
                    _ = navigationController.popToRootViewController(animated: true)
                }
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "handlePushNotification"), object: nil, userInfo: ["postId": id, "notificationString": notificationString, "applicationState": applicationState])
            }
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        //Gather the latestLocation
        setLatestLocation()
        
        //Facebook SDK
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Choozy")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveInstallation(deviceToken: Data){
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.channels = ["global"]
        installation?["user"] = ChoozyUser.current()
        installation?.saveInBackground()
    }
    
    func setLatestLocation(){
        let user = ChoozyUser.current()
        if user != nil{
            getLatestLocation({(geoPoint) in
                user?["latestLocation"] = geoPoint
                user?.saveInBackground()
            })
        }else{
            print("User is nil in setLatestLocation()")
        }
    }
    
    func getLatestLocation(_ completion: @escaping (PFGeoPoint) -> ()){
        PFGeoPoint.geoPointForCurrentLocation(inBackground: {(location: PFGeoPoint?, error: Error?) -> Void in
            if let error = error{
                print("\(error)... during getLatestLocation() from AppDelegate. Resolving using locationManager.getCurrentLocationCoordinates.")
                let location = self.locationManager.getCurrentLocationCoordinates()
                completion(PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
            }else{
                if location != nil{
                    //completion(location!)
                    let location = self.locationManager.getCurrentLocationCoordinates()
                    completion(PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
                }else{
                    let location = self.locationManager.getCurrentLocationCoordinates()
                    completion(PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
                }
            }
        })
    }

}

