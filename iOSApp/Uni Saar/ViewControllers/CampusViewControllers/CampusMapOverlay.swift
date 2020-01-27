//
//  CampusMapOverlay.swift
//  CampusMap
//
//  Created by MacBook Pro on 1/3/20.
//  Copyright © 2020 Serdar. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class CampusMapOverlay: NSObject, MKOverlay {
  var coordinate: CLLocationCoordinate2D
  var boundingMapRect: MKMapRect
  init(campus: CampusModel) {
    boundingMapRect = campus.overlayBoundingMapRect
    coordinate = campus.midCoordinate
  }
}
