//
//  PostButtonCell.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/8/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class PostButtonCell: UITableViewCell {
    
    @IBOutlet var postAuthorImageView: UIImageView!
    @IBOutlet var postButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.blue.dark
    }
}
