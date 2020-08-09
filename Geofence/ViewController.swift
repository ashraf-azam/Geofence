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

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()


    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
//        loadAllGeotifications()
    }

    @IBAction func addRegion(_ sender: Any) {
    }
    
}

