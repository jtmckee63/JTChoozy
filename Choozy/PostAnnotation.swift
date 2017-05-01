//
//  PostAnnotation.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//


import MapKit


class PostAnnotation: NSObject, MKAnnotation {
    //colors JT
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    var black: UIColor = UIColor.black
    
    var post = Post()
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    func blurplePinColor() -> UIColor {
    let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    
    return blurple
    }
}

