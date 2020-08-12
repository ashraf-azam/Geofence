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

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var changeRegion: UIButton!
    @IBOutlet weak var removeGeo: UIButton!
    
    var stateRelay = BehaviorRelay<String?>(value: "")
    
    let locationManager = CLLocationManager()


    override func viewDidLoad() {
        super.viewDidLoad()
        removeMonitoredRegion()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        mapView.setUserTrackingMode(.follow, animated: true)
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
}
    
//MARK: Action
extension ViewController {
    @IBAction func changeRegion(_ sender: Any) {
        print("ok")
        let coordinate = CLLocationCoordinate2DMake(3.139003, 101.686852)
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
            longitude: coordinate.longitude), radius: 200, identifier: "KL")
        mapView.removeOverlays(mapView.overlays)
        locationManager.startMonitoring(for: region)
        let circle = MKCircle(center: coordinate, radius: region.radius)
        mapView.addOverlay(circle)
    }
    
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
