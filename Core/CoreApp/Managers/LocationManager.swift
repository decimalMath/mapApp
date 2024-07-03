import CoreLocation
import MapKit

class LocationSearchManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var lastKnownLocation: CLLocationCoordinate2D?
    var matchingItems: [MKMapItem] = []
    var onSearchComplete: (() -> Void)?

    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location.coordinate
        print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }

    // MARK: - Search Function

    func performSearch(searchBarText: String, completion: @escaping ([MKMapItem]?) -> Void) {
        guard let userLocation = lastKnownLocation else {
            print("User location not available")
            completion(nil)
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText

        // Create a region centered on the user's location
        let regionRadius: CLLocationDistance = 1000 // Search radius in meters
        let region = MKCoordinateRegion(center: userLocation, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response, error) in
            guard let self = self, let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            self.matchingItems = response.mapItems
            completion(self.matchingItems)
        }
    }

    func generateMapImage(for coordinate: CLLocationCoordinate2D, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        options.size = size
        options.mapType = .standard

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                print("Error generating map snapshot: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            let image = UIGraphicsImageRenderer(size: size).image { _ in
                snapshot.image.draw(at: .zero)

                // Add a pin to mark the location
                let pinView = MKMarkerAnnotationView(annotation: nil, reuseIdentifier: nil)
                let pinImage = pinView.image

                var point = snapshot.point(for: coordinate)
                point.x -= pinView.bounds.width / 2
                point.y -= pinView.bounds.height / 2
                point.y -= pinView.centerOffset.y

                pinImage?.draw(at: point)
            }

            completion(image)
        }
    }

}
