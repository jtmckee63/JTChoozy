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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.blue.dark
        headerImageView.contentMode = .scaleAspectFill
    }
    
}
