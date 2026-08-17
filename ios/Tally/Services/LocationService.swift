import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorization: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?
    @Published private(set) var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 250
    }

    func requestAccess() {
        manager.requestAlwaysAuthorization()
    }

    func beginUpdates() {
        guard authorization == .authorizedAlways || authorization == .authorizedWhenInUse else {
            requestAccess(); return
        }
        manager.startUpdatingLocation()
        if authorization == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = true
        }
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedAlways || authorization == .authorizedWhenInUse { beginUpdates() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}

