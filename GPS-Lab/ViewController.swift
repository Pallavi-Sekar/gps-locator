//
//  ViewController.swift
//  GPS-Lab
//
//  Created by Pallavi on 2024-11-04.
//

import MapKit
import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var accelerationLabel: UILabel!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var bottomBarView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!

    let locationManager = CLLocationManager()
    var startLocation: CLLocation?
    var previousLocation: CLLocation?
    var totalDistance: Double = 0.0
    var maxSpeed: Double = 0.0
    var speedSum: Double = 0.0
    var speedCount: Int = 0
    var lastSpeed: Double = 0.0
    var maxAcceleration: Double = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.requestWhenInUseAuthorization()

        // checking the location is enabled or not
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        } else {
            print("Location services are not enabled")
        }

        // setting initial colors for bar
        topBarView.backgroundColor = .gray
        bottomBarView.backgroundColor = .gray
    }

    @IBAction func startTrip(_ sender: UIButton) {
        // resetting the values
        totalDistance = 0.0
        maxSpeed = 0.0
        speedSum = 0.0
        speedCount = 0
        maxAcceleration = 0.0

        locationManager.requestWhenInUseAuthorization()
        bottomBarView.backgroundColor = .green
    }

    @IBAction func stopTrip(_ sender: UIButton) {
        // stop updating the locaions
        locationManager.stopUpdatingLocation()

        // changing bottom bar color to gray
        bottomBarView.backgroundColor = .gray
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()

        case .denied, .restricted:
            showAlertForLocationAccess()

        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        if startLocation == nil {
            startLocation = newLocation
        }

        // update speed
        let currentSpeed = newLocation.speed >= 0 ? newLocation.speed * 3.6 : 0.0 // Convert m/s to km/h
        speedLabel.text = String(format: "%.2f km/h", currentSpeed)

        // track max speed
        if currentSpeed > maxSpeed {
            maxSpeed = currentSpeed
            maxSpeedLabel.text = String(format: "%.2f km/h", maxSpeed)
        }

        // calculate average speed
        speedSum += currentSpeed
        speedCount += 1
        let averageSpeed = speedSum / Double(speedCount)
        averageSpeedLabel.text = String(format: "%.2f km/h", averageSpeed)

        // track max acceleration
        if let previousLocation = previousLocation {
            let timeInterval = newLocation.timestamp.timeIntervalSince(previousLocation.timestamp)
            if timeInterval > 0 {
                let deltaSpeed = currentSpeed - lastSpeed
                let acceleration = abs(deltaSpeed / timeInterval) // Acceleration in km/h/s
                if acceleration > maxAcceleration {
                    maxAcceleration = acceleration
                    accelerationLabel.text = String(format: "%.2f km/h/s", maxAcceleration)
                }
            }
        }
        lastSpeed = currentSpeed

        // calculate total distance
        if let previousLocation = previousLocation {
            let distance = newLocation.distance(from: previousLocation)  // Distance in meters
            totalDistance += distance
            distanceLabel.text = String(format: "%.2f km", totalDistance / 1000) // Convert to km
        }
        previousLocation = newLocation

        // update top bar color based on speed
        topBarView.backgroundColor = currentSpeed > 115 ? .red : .gray

        // update map view with new location
        let region = MKCoordinateRegion(center: newLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)

        print("Current Speed: \(currentSpeed) km/h")
        print("Max Speed: \(maxSpeed) km/h")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

    // this is to ask locaiton access to the user
    func showAlertForLocationAccess() {
        let alert = UIAlertController(title: "Location Access Denied", message: "To use this feature, location access is required. Please enable location services in the Settings app.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}

