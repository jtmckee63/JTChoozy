//
//  CommentCell.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    
    @IBOutlet var backgroundUnderlayView: UIView!
    @IBOutlet var commentUserImageView: ChoozyUserImageView!
    @IBOutlet var commentAuthorLabel: ChoozyUserLabel!
    @IBOutlet var commentLabel: UILabel!
    @IBOutlet var commentDetailButton: CommentDetailButton!
    let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    let lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)
    let black: UIColor = UIColor.black
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.backgroundColor = UIColor.blue.dark
        self.backgroundColor = black
        self.selectionStyle = .none
        
        commentLabel.numberOfLines = 0
        
//        backgroundUnderlayView.backgroundColor = UIColor.blue.dark
        backgroundUnderlayView.backgroundColor = darkGray

    }
    
    
    
}
