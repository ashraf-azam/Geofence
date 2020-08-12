//
//  ViewController.swift
//  Geofence
//
//  Created by HISB-Ashraf on 09/08/2020.
//  Copyright © 2020 HISB-Ashraf. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import RxSwift
import RxCocoa
import DropDown

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var changeRegion: UIButton!
    @IBOutlet weak var removeGeo: UIButton!
    @IBOutlet weak var dropdownMenuView: UIView!
    
    var stateRelay = BehaviorRelay<String?>(value: "")
    var displayDropdownButtonTap : Driver<Void> = .never()
    
    let locationManager = CLLocationManager()
    let menuOptions: [String] = ["Kuala Lumpur", "Mutiara Damansara", "Bukit Kiara"]
    var dropdown: DropDown?
    var isDropdownMenuShown = false
    let disposeBag = DisposeBag()


    override func viewDidLoad() {
        super.viewDidLoad()
        setupTransformInput()
        subscribe()
        dropdownMenuView.visibility = .hidden
        isDropdownMenuShown = false
        setupDropdownMenu()
        removeMonitoredRegion()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        mapView.setUserTrackingMode(.follow, animated: true)
    }
    
    func setupTransformInput() {
        self.displayDropdownButtonTap = changeRegion.rx.tap.asDriver()
    }
    
    func subscribe() {
        let displayDropdown = displayDropdownButtonTap
        .do(onNext: { _ in
            self.displayDropdownMenu()
            })
        disposeBag.insert(displayDropdown.drive())
    }
    
    func setRegion(lat: CLLocationDegrees, long: CLLocationDegrees, identifier: String) {
        let coordinate = CLLocationCoordinate2DMake(lat, long)
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
            longitude: coordinate.longitude), radius: 200, identifier: identifier)
        mapView.removeOverlays(mapView.overlays)
        locationManager.startMonitoring(for: region)
        let circle = MKCircle(center: coordinate, radius: region.radius)
        mapView.addOverlay(circle)
    }
    
    func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func getCurrentLocation() {
        if let currentLocation = locationManager.location {
            // Get location name
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    let street:String = firstLocation?.thoroughfare ?? firstLocation?.name ?? ""
                    let state:String = firstLocation?.subAdministrativeArea ?? ""
                    let fullAddress = [street, state]
                        .compactMap{ $0 }
                        .joined(separator: ", ")
                    
                    let loctionText = "Geofence location : "
                    let fullString = NSMutableAttributedString(string:loctionText)
                    let attrs = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)]
                    let boldString = NSMutableAttributedString(string:fullAddress, attributes:attrs)
                    fullString.append(boldString)
                    
                    self.stateRelay.accept(fullAddress)
                    print(fullAddress)
                }
            })
        }
    }
    
    func removeMonitoredRegion() {
        mapView.removeOverlays(mapView.overlays)
        let monitoredRegions = locationManager.monitoredRegions
        
        for region in monitoredRegions{
            locationManager.stopMonitoring(for: region)
        }
    }
    
    func removeMonitoredRegionWith(identifier: String) {
        let monitoredRegions = locationManager.monitoredRegions
        
        for region in monitoredRegions{
            if region.identifier == identifier {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    func setupDropdownMenu() {
        self.dropdown = DropDown()
        
        dropdown!.anchorView = self.dropdownMenuView
        dropdown!.dataSource = self.menuOptions
        
        // Action triggered on selection
        dropdown!.selectionAction = { [unowned self] (index: Int, item: String) in
            if index == 0 {
                self.setRegion(lat: 3.139003, long: 101.686852, identifier: "KL")
            }
            else if index == 1 {
                self.setRegion(lat: 3.157090, long: 101.610090, identifier: "Mutiara Damansara")
            }
            else if index == 2 {
                self.setRegion(lat: 3.143260, long: 101.643370, identifier: "Mutiara Damansara")
            }
        }
    }
    
    func displayDropdownMenu() {
        if !self.isDropdownMenuShown {
            self.dropdown!.show()
            self.isDropdownMenuShown = true
            
        } else {
            self.dropdown!.hide()
            self.isDropdownMenuShown = false
        }
    }
}
    
//MARK: Action
extension ViewController {
    @IBAction func removeGeo(_ sender: Any) {
        removeMonitoredRegion()
    }

    @IBAction func addRegion(_ sender: Any) {
        guard let longPress = sender as? UILongPressGestureRecognizer else { return }
        let touchLocation = longPress.location(in: mapView)
        let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
        let region = CLCircularRegion(center: coordinate, radius: 200, identifier: "geofence")
        mapView.removeOverlays(mapView.overlays)
        locationManager.startMonitoring(for: region)
        let circle = MKCircle(center: coordinate, radius: region.radius)
        mapView.addOverlay(circle)
    }
}

//MARK: CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        getCurrentLocation()
        mapView.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        getCurrentLocation()
        guard let address = self.stateRelay.value else { return }
        showAlert(title: "Hello", msg: "You've entered \(address)")
        self.statusLabel.text = "Inside"
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let address = self.stateRelay.value else { return }
        showAlert(title: "Goodbve", msg: "You've left \(address)")
        self.statusLabel.text = "Outside"
    }

}

//MARK: MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else { return MKTileOverlayRenderer() }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        circleRenderer.strokeColor = .red
        circleRenderer.fillColor = .red
        circleRenderer.alpha = 0.5
        return circleRenderer
    }
}
