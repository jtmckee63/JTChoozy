//
//  SettingsController.swift
//  Choozy
//
//  Created by Ashley Denton on 4/27/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import Foundation
import UIKit
import Parse
import SwiftyDrop
import AlamofireImage

class SettingsController: UIViewController {
    var videoBackground: BackgroundVideo?
    var user: ChoozyUser?

    @IBOutlet var profilePic: UIImageView!
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var aboutButton: UIButton!
    let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    let lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    let black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)
    
    @IBOutlet weak var tutorialButton: UIButton!
    override func viewDidLoad() {
        //Background Video
        videoBackground = BackgroundVideo(on: self, withVideoURL: "intro.mp4")
        videoBackground?.setUpBackground()
        self.title = "Choozy Settings"
        
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
//        tutorialButton.addTarget(self, action: #selector(showTutorial), for: .touchUpInside)
        aboutButton.addTarget(self, action: #selector(showAbout), for: .touchUpInside)

        if isUserLoggedIn(){
            if let profileImageUrl = user?.profilePictureUrl {
                
                self.profilePic.af_setImage(withURL: URL(string: profileImageUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: profilePic.frame.size), imageTransition: .crossDissolve(0.1))
            }
            
            
        }

        logoutButton.layer.cornerRadius = 0.1 * (logoutButton.bounds.size.width)
        logoutButton.clipsToBounds = true
        
        tutorialButton.layer.cornerRadius = 0.1 * (tutorialButton.bounds.size.width)
        tutorialButton.clipsToBounds = true
        
        aboutButton.layer.cornerRadius = 0.1 * (aboutButton.bounds.size.width)
        aboutButton.clipsToBounds = true
    }
    func logout(){
        ChoozyUser.logOut()
        self.showLoginController()
    }
//    func showTutorial() {
////        showAlert("Choozy Tutorial", message: "This will be the turtorial")
////                    let alertController = UIAlertController(title: "Tutorial", message: "Would You Like To View The Choozy Tutorial?", preferredStyle: .alert)
////                    let dismissHandler = {
////                        (action: UIAlertAction!) in
////                        self.dismiss(animated: true, completion: nil)
////                    }
////        
////                    let onboard = UIAlertAction(title:"OK", style: .default, handler:  { action in self.performSegue(withIdentifier: "onboard", sender: self) } )
////                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: dismissHandler))
////        
////                    alertController.addAction(onboard)
////                    print("THIS WOKRS FOR ONBOARDING __________---------------__________---------")
////        
////                    self.present(alertController, animated: true, completion: nil)
//        performSegue(withIdentifier: "onboard", sender: self)
//        
//    }
    func showAbout() {
        showAlert("About Choozy", message: "Choozy is a crowd sourcing app that gives the user the ability to see what a establishment looks like at real time. This gives the user the ability to both see and show whats going on and where, allowing us to be Choozy ;)")
    }
}
