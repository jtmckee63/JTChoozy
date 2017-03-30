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
        
        placesCollectionView.register(UINib(nibName: "PlaceImageCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        
        self.placesCollectionView.isScrollEnabled = true
        self.placesCollectionView.backgroundColor = UIColor.blue.dark
        self.backgroundColor = UIColor.clear
    }
}
