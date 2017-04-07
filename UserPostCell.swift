//
//  UserPostCell.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/30/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class UserPostCell: UICollectionViewCell {
    
    static let height: CGFloat = 178
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var postDetailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        postDetailLabel.numberOfLines = 0
        
        self.backgroundColor = UIColor.blue.dark
    }

}
