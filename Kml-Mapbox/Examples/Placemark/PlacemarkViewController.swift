//
//  PlacemarkViewController.swift
//  Kml
//
//  Created by Koki Ibukuro on 8/17/15.
//  Copyright (c) 2015 asus4. All rights reserved.
//

import UIKit
import Mapbox

// Placemark to MKAnnotation.
class PlacemarkViewController: UIViewController {

    @IBOutlet weak var mapView: MGLMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        loadKml("sample")
    }

    fileprivate func loadKml(_ path: String) {
        let url = Bundle.main.url(forResource: path, withExtension: "kml")
        KMLDocument.parse(url!, callback:
            { [unowned self] (kml) in
                self.mapView.addAnnotations(kml.annotations)
                self.mapView.showAnnotations(kml.annotations, animated: true)
            }
        )
    }
}

extension PlacemarkViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
}
