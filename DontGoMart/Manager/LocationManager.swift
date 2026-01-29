//
//  LocationManager.swift
//  DontGoMart
//
//  Created by Claude Code
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var nearbyStores: [MartStore] = []

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func findNearbyStores() {
        guard let location = currentLocation else {
            print("❌ [LocationManager] 현재 위치를 알 수 없습니다.")
            return
        }

        let stores = MartStore.allStores
        let storesWithDistance = stores.map { store -> (store: MartStore, distance: Double) in
            let storeLocation = CLLocation(latitude: store.latitude, longitude: store.longitude)
            let distance = location.distance(from: storeLocation)
            return (store, distance)
        }

        nearbyStores = storesWithDistance
            .sorted { $0.distance < $1.distance }
            .prefix(5)
            .map { $0.store }

        print("✅ [LocationManager] 가까운 매장 \(nearbyStores.count)개 발견")
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        findNearbyStores()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            print("❌ [LocationManager] 위치 권한이 거부되었습니다.")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ [LocationManager] 위치 업데이트 실패: \(error.localizedDescription)")
    }
}
