//
//  CampusViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import MapKit
class CampusViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    var searchController: UISearchController!
    var campusCoor = CampusModel(filename: AppSessionManager.shared.selectedCampus.mapCoorFileName)
    var selectedPin: MapPin?
    var selectedCampus: Campus = AppSessionManager.shared.selectedCampus
    var staffAddress: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        selectedCampus = AppSessionManager.shared.selectedCampus
        campusCoor = CampusModel(filename: AppSessionManager.shared.selectedCampus.mapCoorFileName)
        setUpSearchBar()
        mapRegion()
        setupNotification()
    }
    // MARK: - Add methods
    func addOverlay() {
        let overlay = CampusMapOverlay(campus: campusCoor)
        mapView.addOverlay(overlay)
    }
    func mapRegion() {
        let latDelta = campusCoor.overlayTopLeftCoordinate.latitude - campusCoor.overlayBottomRightCoordinate.latitude
        // Think of a span as a tv size, measure from one corner to another
        let span = MKCoordinateSpan(latitudeDelta: fabs(1.8*latDelta), longitudeDelta: 0.0)
        let region = MKCoordinateRegion(center: campusCoor.midCoordinate, span: span)
        mapView.setRegion(region, animated: true)
        self.addOverlay()

    }

    func setUpSearchBar() {

        self.definesPresentationContext = true
        if let buildingSearchTable = self.storyboard!.instantiateViewController(withIdentifier: "BuildingSearchTable") as? BuildingSearchTableViewController {
            self.searchController = UISearchController(searchResultsController: buildingSearchTable)
            self.searchController.searchResultsUpdater = buildingSearchTable
            buildingSearchTable.handleMapSearchDelegate = self
            buildingSearchTable.campusCoordinates = self.loadCoordinates()
        }
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = NSLocalizedString("BuildingsSearch", comment: "")
        if #available(iOS 13, *) {
            self.searchController.searchBar.searchTextField.backgroundColor = .systemBackground
        }
        navigationItem.searchController = self.searchController
        activateSearchBar()

    }
    func activateSearchBar() {
        DispatchQueue.main.async {
            if let staffAddress = self.staffAddress {
                self.searchController?.isActive = true
                self.searchController?.searchBar.text = staffAddress

            }
        }
    }
    func setupNotification() {

        NotificationCenter.default.addObserver(self, selector: #selector(updateCampus), name: NSNotification.Name(rawValue: "CampusSettingsDidUpdate"), object: nil)

    }
    func loadCoordinates() -> [MapInfoModel] {
        if let data = dataFromFile("Campus_Map_Coord") {
            return CampusCoordinatesModel(data: data).mapInfo
        }
        return []
    }

    @objc func getDirections() {
        guard let selectedPin = selectedPin else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: selectedPin.coordinate))
        //let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
        mapItem.name = selectedPin.title
        mapItem.openInMaps(launchOptions: nil)
    }

    @objc func updateCampus() {
        DispatchQueue.main.async {
            self.didChangeLocationFilter(selectedCampus: AppSessionManager.shared.selectedCampus, regionNeedUpdate: true)
        }
    }

    func saveLocation() {
        AppSessionManager.shared.selectedCampus = selectedCampus
        AppSessionManager.saveCampuslocation()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let destination = segue.destination as? UINavigationController, let destinationViewController = destination.topViewController as? ChooseCampusViewController {
            destinationViewController.delegate = self
        }
    }
}

// MARK: - MKMapViewDelegate
extension CampusViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is CampusMapOverlay {
            // campus have been changed for search purpose only
            return CampusMapOverlayView(overlay: overlay, overlayImage: UIImage(named: selectedCampus.mapOverLayerImageName)! )
        }
        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        guard !(annotation is MKUserLocation) else { return nil }
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        annotationView.canShowCallout = true
        let smallSquare = CGSize(width: 35, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        if #available(iOS 13.0, *) {
            button.setBackgroundImage(UIImage(systemName: "car"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        button.addTarget(self, action: #selector(self.getDirections), for: .touchUpInside)
        annotationView.rightCalloutAccessoryView = button

        return annotationView
    }
}
// MARK: - ChooseCampusDelegate
extension CampusViewController: ChooseCampusDelegate {
    func didChangeLocationFilter(selectedCampus: Campus, regionNeedUpdate: Bool) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        campusCoor = CampusModel(filename: selectedCampus.mapCoorFileName)
        self.selectedCampus = selectedCampus
        if regionNeedUpdate {
            mapRegion()
            saveLocation()
        }

    }
}
// MARK: - HandleMapSearch
extension CampusViewController: HandleMapSearch {

    func dropPinZoomIn(placemark: MapPin) {
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        if let pinCampus = placemark.campus, pinCampus != selectedCampus {
            // cache the pin Campus
            didChangeLocationFilter(selectedCampus: pinCampus, regionNeedUpdate: false)
            // update the overlayer map image
            addOverlay()
        }
        mapView.addAnnotation(placemark)
        let latDelta = campusCoor.overlayTopLeftCoordinate.latitude - campusCoor.overlayBottomRightCoordinate.latitude
        var span = MKCoordinateSpan(latitudeDelta: fabs(1*latDelta), longitudeDelta: 0.0)
        if UIDevice.current.userInterfaceIdiom == .pad {
            span = MKCoordinateSpan(latitudeDelta: fabs(0.5*latDelta), longitudeDelta: 0.0)
        }
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}
