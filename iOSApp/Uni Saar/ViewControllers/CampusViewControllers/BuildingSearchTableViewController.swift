//
//  BuildingSearchTableViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/16/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark: MapPin)
    func didChangeLocationFilter(selectedCampus: Campus, regionNeedUpdate: Bool)
}
class BuildingSearchTableViewController: UITableViewController {
    weak var handleMapSearchDelegate: HandleMapSearch?
    var matchingItems: [MapInfoModel] = []
    var campusCoordinates: [MapInfoModel] = []
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
extension BuildingSearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard var searchBarText = searchController.searchBar.text else { return }
        searchBarText = searchBarText.replacingOccurrences(of: "Gebäude ", with: "")
        let withoutSpeace = searchBarText.replacingOccurrences(of: " ", with: "")
        self.matchingItems = campusCoordinates.filter { (item) -> Bool in
            if item.name.range(of: searchBarText, options: .caseInsensitive) != nil {
                return true
            } else {
                if item.name.range(of: withoutSpeace, options: .caseInsensitive) != nil {
                    return true
                }
            }
            if item.function.range(of: searchBarText, options: .caseInsensitive) != nil {
                return true
            }
            return false
        }
        self.tableView.reloadData()
    }
}
extension BuildingSearchTableViewController {
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CampusCell") {
            let selectedItem = matchingItems[indexPath.row]
            cell.textLabel?.text = selectedItem.name
            cell.detailTextLabel?.text = selectedItem.function
            return cell
        }
        return  UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row]
        if selectedItem.campus !=  AppSessionManager.shared.selectedCampus {
            handleMapSearchDelegate?.didChangeLocationFilter(selectedCampus: selectedItem.campus ??  AppSessionManager.shared.selectedCampus, regionNeedUpdate: true)
        }
        if let latitude = CLLocationDegrees(selectedItem.latitude), let longitude = CLLocationDegrees(selectedItem.longitude) {
            let coordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MapPin(coordinate: coordinate2D, title: selectedItem.name, subtitle: selectedItem.function, campus: selectedItem.campus)
            handleMapSearchDelegate?.dropPinZoomIn(placemark: annotation)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension BuildingSearchTableViewController: CampusViewControllerDelegate {
    func didUpdateCoordinatesCache(coordinates: [MapInfoModel]) {
        self.campusCoordinates = coordinates
    }
}
