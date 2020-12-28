// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLocation
import CoreLoggerKit
import CoreModelKit

class LocationController: NSObject {
    public static let sharedInstance = LocationController()

    private var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return locationManager
    }()

    class func sharedController() -> LocationController {
        return sharedInstance
    }

    func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    func locationAccessNotDetermined() -> Bool {
        return CLLocationManager.authorizationStatus() == .notDetermined
    }

    func locationAccessGranted() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorized
    }

    func locationAccessDenied() -> Bool {
        return CLLocationManager.authorizationStatus() == .restricted || CLLocationManager.authorizationStatus() == .denied
    }

    func setDelegate() {
        locationManager.delegate = self
    }

    func determineAndRequestLocationAuthorization() {
        setDelegate()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }

        switch authorizationStatus() {
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationManager.startUpdatingLocation()
        default:
            fatalError("Unexpected Authorization Status")
        }
    }

    private func updateHomeObject(with customLabel: String, coordinates: CLLocationCoordinate2D?) {
        let timezones = DataStore.shared().timezones()

        var timezoneObjects: [TimezoneData] = []

        for timezone in timezones {
            if let model = TimezoneData.customObject(from: timezone) {
                timezoneObjects.append(model)
            }
        }

        for timezoneObject in timezoneObjects where timezoneObject.isSystemTimezone == true {
            timezoneObject.setLabel(customLabel)
            if let latlong = coordinates {
                timezoneObject.longitude = latlong.longitude
                timezoneObject.latitude = latlong.latitude
            }
        }

        var datas: [Data] = []

        for updatedObject in timezoneObjects {
            let dataObject = NSKeyedArchiver.archivedData(withRootObject: updatedObject)
            datas.append(dataObject)
        }

        DataStore.shared().setTimezones(datas)
    }
}

extension LocationController: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty, let coordinates = locations.first?.coordinate else { return }

        let reverseGeoCoder = CLGeocoder()

        reverseGeoCoder.reverseGeocodeLocation(locations[0]) { placemarks, _ in

            guard let customLabel = placemarks?.first?.locality else { return }

            self.updateHomeObject(with: customLabel, coordinates: coordinates)

            self.locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
            updateHomeObject(with: TimeZone.autoupdatingCurrent.identifier, coordinates: nil)
            locationManager.stopUpdatingLocation()
        } else if status == .notDetermined || status == .authorized || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        Logger.info(error.localizedDescription)
    }
}
