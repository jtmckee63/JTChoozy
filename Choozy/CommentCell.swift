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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.blue.dark
        self.selectionStyle = .none
        
        commentLabel.numberOfLines = 0
        
        backgroundUnderlayView.backgroundColor = UIColor.blue.dark
    }
    
    
    
}
