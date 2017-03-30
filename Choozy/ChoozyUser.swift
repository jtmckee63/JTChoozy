//
//  ChoozyUser.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/2/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import Foundation
import Parse

class ChoozyUser: PFUser{
    @NSManaged var profilePictureUrl: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var latestLocation: String?
}
