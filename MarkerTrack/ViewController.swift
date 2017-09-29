//
//  ViewController.swift
//  MarkerTrack
//
//  Created by Mustafa Ezzat on 9/29/17.
//  Copyright © 2017 Waqood. All rights reserved.
//


import UIKit

class ViewController: UIViewController, MarkerTrackDelegate{
    let markerTrack = MarkerTrack()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        markerTrack.delegate = self
        markerTrack.option.googleAPIKey = "AIzaSyAoFyv8ZmDXKjzJJx1_tASPpCWSEFnCoTI"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark: MarkerTrackDelegate
    func locationUpdated() {
        //
        view = markerTrack.mapView
        markerTrack.drawPath()
        
    }
}
