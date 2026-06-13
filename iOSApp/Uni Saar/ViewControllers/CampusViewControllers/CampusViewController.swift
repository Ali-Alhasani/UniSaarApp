//
//  CampusViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import MapKit
import UIKit

@MainActor
protocol CampusViewControllerDelegate: AnyObject {
    func didUpdateCoordinatesCache(coordinates: [MapInfoModel])
}

@MainActor
class CampusViewController: UIViewController {
    @IBOutlet var mapView: MKMapView!
    var searchController: UISearchController!
    var campusCoor = CampusModel(filename: AppSessionManager.shared.selectedCampus.mapCoorFileName)
    var selectedPin: MapPin?
    var selectedCampus: Campus = AppSessionManager.shared.selectedCampus
    var staffAddress: String?
    weak var campusDelegate: CampusViewControllerDelegate?
    private var mapViewModel: MapViewModel?
    private var mapRegionSet = false

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedCampus = AppSessionManager.shared.selectedCampus
        campusCoor = CampusModel(filename: AppSessionManager.shared.selectedCampus.mapCoorFileName)
        setUpSearchBar()
        setupCampusObservation()
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
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
        if let staffAddress {
            searchController?.isActive = true
            searchController?.searchBar.text = staffAddress
        }
    }

    func setupCampusObservation() {
        withObservationTracking {
            _ = AppSessionManager.shared.selectedCampus
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateCampus()
                self?.setupCampusObservation()
            }
        }
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
        guard let selectedPin else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: selectedPin.coordinate))
        mapItem.name = selectedPin.title
        mapItem.openInMaps(launchOptions: nil)
    }

    func updateCampus() {
        didChangeLocationFilter(selectedCampus: AppSessionManager.shared.selectedCampus, regionNeedUpdate: true)
    }

    func saveLocation() {
        AppSessionManager.shared.selectedCampus = selectedCampus
    }

    func updateCoordinateCache(lastChangedDate: String) {
        let mapVM = MapViewModel()
        mapVM.coordinatesLastChanged = lastChangedDate
        mapViewModel = mapVM
        Task { [weak self] in await self?.mapViewModel?.loadGetMapData() }
    }

    override func updateProperties() {
        updateUI()
    }

    private func updateUI() {
        guard let mapVM = mapViewModel, let updatedCoor = mapVM.updatedCoordinates else { return }
        let campusCoordinatesModel = CampusCoordinatesModel(json: updatedCoor)
        campusDelegate?.didUpdateCoordinatesCache(coordinates: campusCoordinatesModel.mapInfo)
        mapViewModel = nil
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
        let reuseID = MKMapViewDefaultAnnotationViewReuseIdentifier
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID, for: annotation) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
        annotationView.canShowCallout = true
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "car")
        let button = UIButton(configuration: config)
        button.frame = CGRect(origin: .zero, size: CGSize(width: 35, height: 30))
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
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
