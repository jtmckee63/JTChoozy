//
//  Post.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import Foundation
import Parse

class Post: PFObject, PFSubclassing{
    
    public static func parseClassName() -> String {
        return "Post"
    }
    
    var id: String?
    var likes: Int?
    var views: Int?
    
    var placeId: String?
    var placeName: String?
    
    var subAddress: String?
    var address: String?
    var city: String?
    var state: String?
    var country: String?
    var location: PFGeoPoint?
    
    var author: ChoozyUser?
    var authorId: String?
    
    var mediaUrl: String?
    
    var timeStamp: Date?
    var updatedTimeStamp: Date?
}
