//
//  Comment.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import Foundation
import Parse

class Comment: PFObject, PFSubclassing{
    
    public static func parseClassName() -> String {
        return "Comment"
    }
    
    var id: String?
    var comment: String?
    
    var author: ChoozyUser?
    var postId: String?
    
    var timeStamp: Date?
    var updatedTimeStamp: Date?
}
