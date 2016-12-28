//
//  PathViewController.swift
//  Kml
//
//  Created by Koki Ibukuro on 8/18/15.
//  Copyright (c) 2015 asus4. All rights reserved.
//

import UIKit
import Mapbox

// Path to MKPolylineRenderer
// Polygon to MKPolygonRenderer
class PathViewController: UIViewController {

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
                self.mapView.add(kml.overlays)
                self.mapView.addAnnotations(kml.annotations)
                self.mapView.showAnnotations(kml.annotations, animated: true)
            }
        )
    }
}

extension PathViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return annotation.alpha
    }
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return annotation.strokeColor ?? UIColor.black
    }
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return annotation.fillColor ?? UIColor.lightGray
    }
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return annotation.lineWidth
    }
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
}
