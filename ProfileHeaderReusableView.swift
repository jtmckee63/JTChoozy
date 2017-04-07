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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.blue.extraDark
    }
    
}
