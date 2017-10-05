//
//  MarkerTrack.swift
//  ARCarMovementSwift
//
//  Created by Mustafa Ezzat on 9/23/17.
//  Copyright © 2017 Antony Raphel. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
//import GoogleMaps

protocol MarkerTrackDelegate {
    func locationUpdated()
}

enum API {
    static let apiUrl = "https://maps.googleapis.com/maps/api/directions/"
    enum Params {
        enum Keys{
            static let origin = "origin="
            static let destination = "destination="
            static let mode = "mode="
            static let key = "key="
        }
    }
}

public struct Option{
    var oldCoordinate = CLLocationCoordinate2DMake(CLLocationDegrees(40.74317), CLLocationDegrees(-74.00854))
    var finalCoordinate = CLLocationCoordinate2DMake(CLLocationDegrees(40.81210), CLLocationDegrees(-74.07241))
    var googleAPIKey = "Your API Key"
    var mapMode = "driving"
    var markerImage = "car.png"
    var intervalTime = 2.0
    var strokeColor = UIColor(red: 0, green: 150.0/255.0, blue: 136.0/255.0, alpha: 1.0)
    var strokeWidth:CGFloat = 5
}

public class MarkerTrack: NSObject{
   
    var delegate:MarkerTrackDelegate!
    
    var driverMarker: GMSMarker!
    var mapView: GMSMapView! = nil
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var zoomLevel: Float = 16.0
    var cameraLocation:CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    var coordinates = [CLLocationCoordinate2D]()
    var timer: Timer! = nil
    var counter: NSInteger!
    var option = Option()

    override init() {
        super.init()
        counter = 0
        handleLocationManager()
    }
    public func handleCamera(coordinate:CLLocationCoordinate2D){
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        delegate.locationUpdated()
        //mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        // Add the map to the view, hide it until we&#39;ve got a location update.
        // mapView.isHidden = false
    }
    public func handleLocationManager(){
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50.0
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    public func createMarker(){
        driverMarker = GMSMarker()
        driverMarker.position = option.oldCoordinate
        driverMarker.icon = UIImage(named: "\(option.markerImage)")
        driverMarker.map = mapView
    }

    
    public func move(marker:GMSMarker, source:CLLocationCoordinate2D, destination:CLLocationCoordinate2D, inMapView:GMSMapView, withBearing:Double){
        let bearing = getBearing(source: source, destination: destination)
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.rotation = bearing
        marker.position = source
        
        CATransaction.begin()
        CATransaction.setValue(Int(2.0), forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({() -> Void in
            marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
            marker.rotation = bearing
            self.moveMarker(marker: marker)
        })
        
        marker.position = destination
        marker.map = inMapView
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.rotation = bearing
        CATransaction.commit()
    }
    
    public func getBearing(source: CLLocationCoordinate2D ,destination: CLLocationCoordinate2D) -> Double {
        func degreesToRadians(degrees: Double) -> Double { return degrees * Double.pi / 180.0 }
        func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / Double.pi }
        
        let sourceLatitude = degreesToRadians(degrees: source.latitude)
        let sourceLongitude = degreesToRadians(degrees: source.longitude)
        
        let destinationLatitude = degreesToRadians(degrees: destination.latitude);
        let destinationLongitude = degreesToRadians(degrees: destination.longitude);
        
        let deltaLongitude = destinationLongitude - sourceLongitude;
        
        let y = sin(deltaLongitude) * cos(destinationLatitude);
        let x = cos(sourceLatitude) * sin(destinationLatitude) - sin(sourceLatitude) * cos(destinationLatitude) * cos(deltaLongitude);
        let radiansBearing = atan2(y, x);
        
        return radiansToDegrees(radians: radiansBearing)
    }
    
    public func drawPath()
    {
        let params = API.Params.self        
        let url = API.apiUrl + "json?" + params.Keys.origin + "\(option.oldCoordinate.latitude),\(option.oldCoordinate.longitude)" + "&"  + params.Keys.destination + "\(option.finalCoordinate.latitude),\(option.finalCoordinate.longitude)" + "&"  + params.Keys.mode +  "\(option.mapMode)" + "&"  + params.Keys.key +  "\(option.googleAPIKey)"
        
        
        Alamofire.request(url).responseJSON { response in
            let json = JSON(data: response.data!)
            let routes = json["routes"].arrayValue
            
            for route in routes
            {
                print("route: \(route)")
                
                let routeOverviewPolyline = route["overview_polyline"].dictionary
                let points = routeOverviewPolyline?["points"]?.stringValue
                
                let path = GMSPath.init(fromEncodedPath: points!)
                let n = Int((path?.count())!)
                for i in 0..<n{
                    let coordinate = path?.coordinate(at: UInt(i))
                    self.coordinates.append(coordinate!)
                }
                
                let polyline = GMSPolyline.init(path: path)
                polyline.map = self.mapView
                polyline.strokeColor = self.option.strokeColor
                polyline.strokeWidth = self.option.strokeWidth
            }
            self.timer = Timer.scheduledTimer(timeInterval: self.option.intervalTime, target: self, selector: #selector(self.timerTriggered), userInfo: nil, repeats: true)
        }
    }
    
    public func timerTriggered() {
        if counter < coordinates.count {
            let newCoordinate = coordinates[counter]
            move(marker: driverMarker, source: option.oldCoordinate, destination: newCoordinate, inMapView: mapView, withBearing: 0)
            option.oldCoordinate = newCoordinate
            counter = counter + 1
        }
        else {
            timer.invalidate()
            timer = nil
        }
    }
    
    public func moveMarker(marker: GMSMarker){
        driverMarker = marker
        driverMarker.map = mapView
        
        let updatedCamera = GMSCameraUpdate.setTarget(driverMarker.position, zoom: 15.0)
        mapView.animate(with: updatedCamera)
    }
}

// Delegates to handle events for the location manager.
extension MarkerTrack: CLLocationManagerDelegate, GMSMapViewDelegate {
    
    // Handle incoming location events.
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        
        option.oldCoordinate = location.coordinate
        option.finalCoordinate.latitude = location.coordinate.latitude + 0.01
        option.finalCoordinate.longitude = location.coordinate.longitude + 0.01
        
        handleCamera(coordinate: location.coordinate)
        createMarker()
        
        locationManager.delegate = nil
    }
    
    // Handle authorization for the location manager.
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
    public func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        cameraLocation = position.target
    }
    
}
