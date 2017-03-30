//
//  LoginController.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/2/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import ParseFacebookUtilsV4
import FBSDKCoreKit
import SwiftyDrop

class LoginController: UIViewController {
    
    var videoBackground: BackgroundVideo?
    @IBOutlet var logginButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Background Video
        videoBackground = BackgroundVideo(on: self, withVideoURL: "intro.mp4")
        videoBackground?.setUpBackground()
        
        //Title Label
        titleLabel.text = "Choozy"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "Avenir-Black", size: 96)
        titleLabel.textColor = UIColor.white.flat
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.alpha = 1
        
        //Login Button
        logginButton.setTitleColor(UIColor.white, for: UIControlState())
        logginButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 20)
        logginButton.backgroundColor = UIColor.blue.flat
        logginButton.alpha = 1
        logginButton.addTarget(self, action: #selector(self.facebookLoginOrRegister), for: .touchUpInside)
        logginButton.setTitle("Login with Facebook", for: .normal)
    }
    
    func facebookLoginOrRegister(){
        
        let permissions = ["email", "public_profile"]
        PFFacebookUtils.logInInBackground(withReadPermissions: permissions, block: {(user: PFUser?, error: Error?) -> Void in
            
            if let error = error{
                print(error)
            }
            
            if let user = user{
                if user.isNew{
                    self.facebookRegisterUser()
                }else{
                    
                    guard let choozyUser = user as? ChoozyUser else{
                        return
                    }
                    
                    if let _ = choozyUser.firstName, let _ = choozyUser.lastName, let _ = choozyUser.profilePictureUrl{
                        
                        self.dismissViewController()
                        
                        //Refresh Our Data after we finish creating an account.
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshAllData"), object: nil, userInfo: nil)
                    }else{
                        self.showSCLAlert("Uh Oh...", message: "It looks like we couldn't authenticate your account with Facebook. Please try again.", image: UIImage(named: "settingsIcon")!)
                    }
                }
            } else {
                print("Facebook login cancelled")
            }
        })
    }
    
    func facebookRegisterUser(){
        
        if FBSDKAccessToken.current() != nil{
            
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, last_name"]).start(completionHandler: {(connection, result, error) -> Void in
                
                if (error == nil){
                    
                    let data: [String:AnyObject] = result as! [String : AnyObject]
                    
                    if
                        let id = data["id"] as? String,
                        let firstName = data["first_name"] as? String,
                        let lastName = data["last_name"] as? String {
                        
                        let profileImageUrl = URL(string: "https://graph.facebook.com/\(id)/picture?type=large&width=1000&height=1000")!
                        
                        let profileImageData: Data = try! Data(contentsOf: profileImageUrl)
                        
                        if let userId = ChoozyUser.current()?.objectId{
                            
                            let photo = PFFile(name: "user_" + userId + ".jpeg", data: profileImageData)
                            photo?.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                if let error = error{
                                    print(error)
                                }else{
                                    if success{
                                        
                                        guard let url = photo?.url else{
                                            return
                                        }
                                        
                                        ChoozyUser.current()?["profilePictureUrl"] = url
                                        ChoozyUser.current()?["firstName"] = firstName
                                        ChoozyUser.current()?["lastName"] = lastName
                                        ChoozyUser.current()?.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                            if let error = error{
                                                print(error)
                                            }else{
                                                if success{
                                                    
                                                    Drop.upAll()
                                    
                                                    self.dismissViewController()
                                                    
                                                    //Refresh Our Data after we finish creating an account.
                                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshAllData"), object: nil, userInfo: nil)
                                                    
                                                }else{
                                                    print("Failed to save Profile Picture")
                                                }
                                            }
                                        })
                                    }else{
                                        print("Failed to save Profile Picture")
                                    }
                                }
                            })
                        }
                    }else{
                        self.showSCLAlert("Uh Oh...", message: "It looks like we couldn't authenticate your account with Facebook. Please try again later.", image: UIImage(named: "settingsIcon")!)
                    }
                }
            })
        }
    }
    
    //MARK: - Status Bar Override methods
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
