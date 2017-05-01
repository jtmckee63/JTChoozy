//
//  PostHeaderReusableView.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class PostHeaderReusableView: UICollectionReusableView {

    @IBOutlet var headerImageView: UIImageView!
    
    @IBOutlet var postButton: UIButton!
    let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    let lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    let black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.backgroundColor = UIColor.blue.dark
        print("inside PostHeaderReusableView.swift")
        self.backgroundColor = darkGray
        headerImageView.contentMode = .scaleAspectFill
    }
    
}
