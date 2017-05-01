//
//  PostCommentCell.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/8/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit

class PostCommentCell: UITableViewCell {
    
    @IBOutlet var commentTextField: UITextField!
    let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    let lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    let black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
//        self.backgroundColor = UIColor.blue.light
        self.backgroundColor = darkGray
        self.selectionStyle = .none
        
//        commentTextField.backgroundColor = UIColor.blue.dark
        commentTextField.backgroundColor = darkGray
        commentTextField.textColor = UIColor.white
        commentTextField.attributedPlaceholder = NSAttributedString(string:"Say something about this place...", attributes: [NSForegroundColorAttributeName: UIColor.white.flat.withAlphaComponent(0.7)])
        commentTextField.tintColor = UIColor.white.flat
    }
}
