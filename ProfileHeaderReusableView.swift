//
//  ProfileHeaderReusableView.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/30/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class ProfileHeaderReusableView: UICollectionReusableView {
    
    static let height: CGFloat = 230
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var viewsTitleLabel: UILabel!
    @IBOutlet var postsTitleLabel: UILabel!
    @IBOutlet var likesTitleLabel: UILabel!
    @IBOutlet var viewsLabel: UILabel!
    @IBOutlet var postsLabel: UILabel!
    @IBOutlet var likesLabel: UILabel!
    
    @IBOutlet var badge: UIImageView!
    let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    let lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    let black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.backgroundColor = UIColor.blue.extraDark
        self.backgroundColor = black
    }
    
}
