//
//  CampusViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import MapKit
import Combine

protocol CampusViewControllerDelegate: AnyObject {
    func didUpdateCoordinatesCache(coordinates: [MapInfoModel])
}

class CampusViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    var searchController: UISearchController!
    var campusCoor = CampusModel(filename: AppSessionManager.shared.selectedCampus.mapCoorFileName)
    var selectedPin: MapPin?
    var selectedCampus: Campus = AppSessionManager.shared.selectedCampus
    var staffAddress: String?
    weak var campusDelegate: CampusViewControllerDelegate?
    private var mapViewModel: MapViewModel?
    private var mapUpdateCancellable: AnyCancellable?
    private var mapRegionSet = false

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedCampus = AppSessionManager.shared.selectedCampus
        campusCoor = CampusModel(filename: AppSessionManager.shared.selectedCampus.mapCoorFileName)
        setUpSearchBar()
        setupNotification()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !mapRegionSet else { return }
        mapRegionSet = true
        mapRegion()
    }

    // MARK: - Add methods
    func addOverlay() {
        let overlay = CampusMapOverlay(campus: campusCoor)
        mapView.addOverlay(overlay)
    }

    func mapRegion() {
        let latDelta = campusCoor.overlayTopLeftCoordinate.latitude - campusCoor.overlayBottomRightCoordinate.latitude
        let span = MKCoordinateSpan(latitudeDelta: fabs(1.8 * latDelta), longitudeDelta: 0.0)
        let region = MKCoordinateRegion(center: campusCoor.midCoordinate, span: span)
        mapView.setRegion(region, animated: true)
        addOverlay()
    }

    func setUpSearchBar() {
        definesPresentationContext = true
        if let buildingSearchTable = storyboard?.instantiateViewController(withIdentifier: "BuildingSearchTable") as? BuildingSearchTableViewController {
            searchController = UISearchController(searchResultsController: buildingSearchTable)
            searchController.searchResultsUpdater = buildingSearchTable
            buildingSearchTable.handleMapSearchDelegate = self
            buildingSearchTable.campusCoordinates = loadCoordinates()
            campusDelegate = buildingSearchTable
        }
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("BuildingsSearch", comment: "")
        searchController.searchBar.searchTextField.backgroundColor = .systemBackground
        navigationItem.searchController = searchController
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

    func loadCoordinates(checkForUpdate: Bool = true) -> [MapInfoModel] {
        if let data = Data.dataFromFile(withFilename: "Campus_Map_Coord") {
            let campusCoordinatesModel = CampusCoordinatesModel(data: data)
            updateCoordinateCache(lastChangedDate: campusCoordinatesModel.updateTime)
            return campusCoordinatesModel.mapInfo
        }
        return []
    }

    @objc func getDirections() {
        guard let selectedPin = selectedPin else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: selectedPin.coordinate))
        mapItem.name = selectedPin.title
        mapItem.openInMaps(launchOptions: nil)
    }

    @objc func updateCampus() {
        didChangeLocationFilter(selectedCampus: AppSessionManager.shared.selectedCampus, regionNeedUpdate: true)
    }

    func saveLocation() {
        AppSessionManager.shared.selectedCampus = selectedCampus
        AppSessionManager.saveCampuslocation()
    }

    func updateCoordinateCache(lastChangedDate: String) {
        let vm = MapViewModel()
        vm.coordinatesLastChanged = lastChangedDate
        mapViewModel = vm
        mapUpdateCancellable = vm.$didUpdateCoordinates
            .dropFirst()
            .first()
            .sink { [weak self] updatedCoor in
                guard let self else { return }
                let campusCoordinatesModel = CampusCoordinatesModel(json: updatedCoor)
                campusDelegate?.didUpdateCoordinatesCache(coordinates: campusCoordinatesModel.mapInfo)
                mapViewModel = nil
                mapUpdateCancellable = nil
            }
        vm.loadGetMapData()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UINavigationController,
           let destinationViewController = destination.topViewController as? ChooseCampusViewController {
            destinationViewController.delegate = self
        }
    }
}

// MARK: - MKMapViewDelegate
extension CampusViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is CampusMapOverlay {
            return CampusMapOverlayView(overlay: overlay, overlayImage: UIImage(named: selectedCampus.mapOverLayerImageName)!)
        }
        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        annotationView.canShowCallout = true
        let smallSquare = CGSize(width: 35, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(systemName: "car"), for: .normal)
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
        selectedPin = placemark
        mapView.removeAnnotations(mapView.annotations)
        if let pinCampus = placemark.campus, pinCampus != selectedCampus {
            didChangeLocationFilter(selectedCampus: pinCampus, regionNeedUpdate: false)
            addOverlay()
        }
        mapView.addAnnotation(placemark)
        let latDelta = campusCoor.overlayTopLeftCoordinate.latitude - campusCoor.overlayBottomRightCoordinate.latitude
        var span = MKCoordinateSpan(latitudeDelta: fabs(1 * latDelta), longitudeDelta: 0.0)
        if UIDevice.current.userInterfaceIdiom == .pad {
            span = MKCoordinateSpan(latitudeDelta: fabs(0.5 * latDelta), longitudeDelta: 0.0)
        }
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}
