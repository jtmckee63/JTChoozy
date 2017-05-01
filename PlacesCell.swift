//
//  PlacesCell.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/6/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class PlacesCell: UITableViewCell {
    
    @IBOutlet var placesCollectionView: UICollectionView!

    override func awakeFromNib() {
        super.awakeFromNib()
        let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
        let lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
        let black: UIColor = UIColor.black
        let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)
        
        placesCollectionView.register(UINib(nibName: "PlaceImageCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        
        self.placesCollectionView.isScrollEnabled = true
//        self.placesCollectionView.backgroundColor = UIColor.blue.light
        self.placesCollectionView.backgroundColor = darkGray
        self.placesCollectionView.showsVerticalScrollIndicator = false
        self.placesCollectionView.showsHorizontalScrollIndicator = false
        self.backgroundColor = UIColor.clear
    }
}
