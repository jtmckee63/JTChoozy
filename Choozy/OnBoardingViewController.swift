//
//  OnBoardingViewController.swift
//  Choozy
//
//  Created by Ashley Denton on 6/20/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit
import paper_onboarding
class OnBoardingViewController: UIViewController, PaperOnboardingDataSource, PaperOnboardingDelegate {
    
    
//    @IBOutlet weak var onBoardingView: OnBoardingView!
//    @IBOutlet weak var getStartedButton: UIButton!
    
    @IBOutlet weak var onBoardingView: OnBoardingView!
    @IBOutlet weak var getStartedButton: UIButton!
    //colors JT
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    var lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    var black: UIColor = UIColor.black
    
    var user: ChoozyUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onBoardingView.dataSource = self
        onBoardingView.delegate = self
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //onboarding - JT added
    func onboardingItemsCount() -> Int {
        return 6
    }
    //onboarding - JT added
    func onboardingItemAtIndex(_ index: Int) -> OnboardingItemInfo {
        let backgroundColorOne = blurple
        let backgroundColorTwo = lightGreen
        let backgroundColorThree = blurple
        let backgroundColorFour = lightGreen
        let backgroundColorFive = blurple
        let backgroundColorSix = lightGreen
        
        let titleFont = UIFont(name: "AvenirNext-Bold", size: 24)!
        let descriptionFont = UIFont(name: "AvenirNext-Regular", size: 18)!
        
        return [
            ("onBoardPin", "Recent Posts Near You", "Checkout all of the posts within the last 48 hours in your area! Check out the post by selecting the pin and then the far right Choozy icon. Maybe you just need directions? Get directions by selecting the left Car Icon", "", backgroundColorOne, UIColor.white, UIColor.white, titleFont, descriptionFont),
            ("onBoardPost", "Tap To See!", "While checking out the post you have selected, you should leave a comment or like that post!", "", backgroundColorTwo, UIColor.black, UIColor.black, titleFont, descriptionFont),
            ("onBoardSearch", "Search For A Place", "No one has posted at the place you were looking for? Just type the place in the search bar and check out the recent posts.", "", backgroundColorThree, UIColor.white, UIColor.white, titleFont, descriptionFont),
            ("onBoardDrop", "Cant Decide?", "Maybe you want Choozy to choose? Select a genre from the drop down list to show options near you!", "", backgroundColorFour, UIColor.black, UIColor.black, titleFont, descriptionFont),
            ("onBoardPlace", "Place Specific!", "Know where you want to post? Search for a place or select one from Choozy's choices and view the the posts for that place! If you want to post there just press 'Tap To Post' button to make a post", "", backgroundColorFive, UIColor.white, UIColor.white, titleFont, descriptionFont),
            ("onBoardProfile", "Make Your Profile Shine!", "Earn your level and show people why your choices are the way to go!", "", backgroundColorSix, UIColor.black, UIColor.black, titleFont, descriptionFont)
            ][index]
    }

    func onboardingConfigurationItem(_ item: OnboardingContentViewItem, index: Int) {
        
    
    }
    
    func onboardingWillTransitonToIndex(_ index: Int) {
        if index == 3 {
            if self.getStartedButton.alpha == 1 {
                UIView.animate(withDuration: 0.2, animations: {
                    self.getStartedButton.alpha = 0
                })
            }
        }
    }
    
    func onboardingDidTransitonToIndex(_ index: Int) {
        if index == 4 {
            UIView.animate(withDuration: 0.4, animations: {
                self.getStartedButton.alpha = 1
            })
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func gotStarted(_ sender: Any) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "onBoardingComplete")
        
        userDefaults.synchronize()
    }
}
