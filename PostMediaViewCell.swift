//
//  PostMediaViewCell.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/6/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class PostMediaViewCell: UITableViewCell {
    
    @IBOutlet var mediaView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
    }
}
