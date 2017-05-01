//
//  PlaceImageCell.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/6/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class PlaceImageCell: UICollectionViewCell {

    @IBOutlet var placeImageView: UIImageView!
    @IBOutlet var placeLabel: UILabel!
    let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    let lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    let black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.backgroundColor = UIColor.blue.dark
        self.backgroundColor = black
        placeImageView.contentMode = .scaleAspectFit
        placeLabel.numberOfLines = 0
        
        // Initialization code
    }

}
