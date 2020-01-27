//
//  CampusMapOverlayView.swift
//  CampusMap
//
//  Created by MacBook Pro on 1/3/20.
//  Copyright © 2020 Serdar. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class CampusMapOverlayView: MKOverlayRenderer {
  var overlayImage: UIImage
  init(overlay: MKOverlay, overlayImage: UIImage) {
    self.overlayImage = overlayImage
    super.init(overlay: overlay)
  }
  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard let imageReference = overlayImage.cgImage else { return }
    let rect = self.rect(for: overlay.boundingMapRect)
    context.scaleBy(x: 1, y: -1)
    context.translateBy(x: 0.0, y: -rect.size.height)
    context.rotate(by: 0.0)
    context.draw(imageReference, in: rect)
  }
}
