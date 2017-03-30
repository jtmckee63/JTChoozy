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
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        
        commentTextField.backgroundColor = UIColor.clear
        commentTextField.textColor = UIColor.white
        commentTextField.attributedPlaceholder = NSAttributedString(string:"Say something about this place...", attributes: [NSForegroundColorAttributeName: UIColor.white.flat.withAlphaComponent(0.7)])
        commentTextField.tintColor = UIColor.white.flat
    }
}
