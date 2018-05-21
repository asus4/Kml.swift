//
//  PathViewController.swift
//  Kml
//
//  Created by Koki Ibukuro on 8/18/15.
//  Copyright (c) 2015 asus4. All rights reserved.
//

import UIKit
import MapKit

// Path to MKPolylineRenderer
// Polygon to MKPolygonRenderer
class PathViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        loadKml("sample")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    fileprivate func loadKml(_ path: String) {
        let url = Bundle.main.url(forResource: path, withExtension: "kml")
        KMLDocument.parse(url: url!, callback:
            { [unowned self] (kml) in
                // Add overlays
                self.mapView.addOverlays(kml.overlays)
                // Add annotations
                self.mapView.showAnnotations(kml.annotations, animated: true)
            }
        )
    }
}

extension PathViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlayPolyline = overlay as? KMLOverlayPolyline {
            // return MKPolylineRenderer
            return overlayPolyline.renderer()
        }
        if let overlayPolygon = overlay as? KMLOverlayPolygon {
            // return MKPolygonRenderer
            return overlayPolygon.renderer()
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
