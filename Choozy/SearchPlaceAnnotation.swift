//
//  SearchPlaceAnnotation.swift
//  Choozy
//
//  Created by Cameron Eubank on 4/6/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import MapKit

class SearchPlaceAnnotation: NSObject, MKAnnotation {
    
    var searchPlace = SearchPlace()
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
