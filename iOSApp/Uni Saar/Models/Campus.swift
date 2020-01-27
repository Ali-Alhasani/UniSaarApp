//
//  Campus.swift
//  CampusMap
//
//  Created by MacBook Pro on 1/3/20.
//  Copyright © 2020 Serdar. All rights reserved.
//

import UIKit
import MapKit

class CampusModel {
    var name: String?
    var midCoordinate = CLLocationCoordinate2D()
    var overlayTopLeftCoordinate = CLLocationCoordinate2D()
    var overlayTopRightCoordinate = CLLocationCoordinate2D()
    var overlayBottomLeftCoordinate = CLLocationCoordinate2D()
    var overlayBottomRightCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(overlayBottomLeftCoordinate.latitude,
                                          overlayTopRightCoordinate.longitude)
    }
    var overlayBoundingMapRect: MKMapRect {
        let topLeft = MKMapPoint(overlayTopLeftCoordinate)
        let topRight = MKMapPoint(overlayTopRightCoordinate)
        let bottomLeft = MKMapPoint(overlayBottomLeftCoordinate)
        return MKMapRect(
            x: topLeft.x,
            y: topLeft.y,
            width: fabs(topLeft.x - topRight.x),
            height: fabs(topLeft.y - bottomLeft.y))
    }
    init(filename: String) {
        guard let properties = CampusModel.plist(filename) as? [String: Any] else {return}
        midCoordinate = CampusModel.parseCoord(dict: properties, fieldName: "midCoord")
        overlayTopLeftCoordinate = CampusModel.parseCoord(dict: properties, fieldName: "overlayTopLeftCoord")
        overlayTopRightCoordinate = CampusModel.parseCoord(dict: properties, fieldName: "overlayTopRightCoord")
        overlayBottomLeftCoordinate = CampusModel.parseCoord(dict: properties, fieldName: "overlayBottomLeftCoord")
    }
    static func plist(_ plist: String) -> Any? {
        guard let filePath = Bundle.main.path(forResource: plist, ofType: "plist"),
            let data = FileManager.default.contents(atPath: filePath) else { return nil }
        do {
            return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            return nil
        }
    }
    static func parseCoord(dict: [String: Any], fieldName: String) -> CLLocationCoordinate2D {
        if let coord = dict[fieldName] as? String {
            let point = NSCoder.cgPoint(for: coord)
            return CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
        }
        return CLLocationCoordinate2D()
    }
}

class MapPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var campus: Campus?

    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, campus: Campus?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.campus = campus
    }
}
