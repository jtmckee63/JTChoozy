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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.blue.dark
        
        placeImageView.contentMode = .scaleAspectFit
        placeLabel.numberOfLines = 0
        
        // Initialization code
    }

}
