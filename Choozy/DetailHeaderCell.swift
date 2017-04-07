//
//  DetailHeaderCell.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class DetailHeaderCell: UITableViewCell {
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerImageView: ChoozyUserImageView!
    @IBOutlet var headerAuthorLabel: ChoozyUserLabel!
    @IBOutlet var headerPlaceLabel: ChoozyPlaceLabel!
    @IBOutlet var postImageView: UIImageView!
    @IBOutlet var actionView: UIView!
    @IBOutlet var likePostButton: UIButton!
    @IBOutlet var likesLabel: UILabel!
    @IBOutlet var viewsImageView: UIImageView!
    @IBOutlet var viewsLabel: UILabel!
    @IBOutlet var commentButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.blue.extraDark
        self.selectionStyle = .none
        
        headerView.backgroundColor = UIColor.black.flat.withAlphaComponent(0.85)
        actionView.backgroundColor = UIColor.black.flat.withAlphaComponent(0.85)
    }
}
