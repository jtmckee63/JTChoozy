//
//  MyAnnotation.swift
//  Choozy
//
//  Created by Ashley Denton on 4/9/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MyAnnotation: NSObject, MKAnnotation {
    var annotationView = MKPinAnnotationView()
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var title: String!
    var place = Place()
    var post = Post()
    
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.coordinate = coordinate
        self.title = title
    }
    
}
