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
    @IBOutlet weak var tutorialButton: UIButton!
    @IBOutlet weak var aboutButton: UIButton!
    
    
    override func viewDidLoad() {
        //Background Video
        videoBackground = BackgroundVideo(on: self, withVideoURL: "intro.mp4")
        videoBackground?.setUpBackground()
        self.title = "Choozy Settings"
        
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        tutorialButton.addTarget(self, action: #selector(showTutorial), for: .touchUpInside)
        aboutButton.addTarget(self, action: #selector(showAbout), for: .touchUpInside)
        
        if isUserLoggedIn(){
            if let profileImageUrl = user?.profilePictureUrl {
                
                self.profilePic.af_setImage(withURL: URL(string: profileImageUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: profilePic.frame.size), imageTransition: .crossDissolve(0.1))
            }
            
            
        }
        
    }
    func logout(){
        ChoozyUser.logOut()
        self.showLoginController()
    }
    func showTutorial() {
        showAlert("Choozy Tutorial", message: "This will be the turtorial")
    }
    func showAbout() {
        showAlert("About Choozy", message: "Choozy is a crowd sourcing app that gives the user the ability to see what a establishment looks like at real time. This gives the user the ability to both see and show whats going on and where, allowing us to be Choozy ;)")
    }
}
