//
//  KML+Mapbox.swift
//  Kml
//
//  Created by Greg Pardo on 12/28/16.
//  Copyright © 2016 asus4. All rights reserved.
//

import Mapbox
import AEXML

// MARK: - Mapbox bridge
public protocol KMLOverlay: MGLOverlay {
    var style: KMLStyle? { get set }
    func renderer() -> KMLOverlayRenderer
}
open class KMLMapboxOverlayRenderer: KMLOverlayRenderer {
    public var alpha: CGFloat = 1.0
}
open class KMLMapboxOverlayPathRenderer: KMLOverlayRenderer {
    public var alpha: CGFloat = 1.0
    public var fillColor: UIColor? = UIColor(red: 0.6, green: 1.0, blue: 0.5, alpha: 0.2)
    public var strokeColor: UIColor? = UIColor(red: 1.0, green: 0.6, blue: 0.5, alpha: 0.8)
    public var lineWidth: CGFloat = 2.0
}
open class KMLMapboxPolygonRenderer: KMLMapboxOverlayPathRenderer {
}
open class KMLMapboxPolylineRenderer: KMLMapboxOverlayPathRenderer {
}
open class KMLAnnotation: NSObject, MGLAnnotation {
    open var coordinate: CLLocationCoordinate2D
    open var title: String?
    open var subtitle: String?
    open var style: KMLStyle?
    init(_ coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

open class KMLOverlayPolygon: MGLPolygon, KMLOverlay {
    open var style: KMLStyle? = nil
    open func renderer() -> KMLOverlayRenderer {
        let renderer: KMLMapboxPolygonRenderer = KMLMapboxPolygonRenderer()
        if style != nil {
            style?.applyStyle(renderer)
        } else {
            renderer.fillColor = UIColor(red: 0.6, green: 1.0, blue: 0.5, alpha: 0.2)
            renderer.strokeColor = UIColor(red: 1.0, green: 0.6, blue: 0.5, alpha: 0.8)
            renderer.lineWidth = 2.0
        }
        return renderer
    }
}

open class KMLOverlayPolyline: MGLPolyline, KMLOverlay {
    open var style: KMLStyle? = nil
    open func renderer() -> KMLOverlayRenderer {
        let renderer: KMLMapboxPolylineRenderer = KMLMapboxPolylineRenderer()
        if style != nil {
            style?.applyStyle(renderer)
        } else {
            renderer.strokeColor = UIColor(red: 0.6, green: 0.6, blue: 1.0, alpha: 0.8)
            renderer.lineWidth = 2.0
        }
        return renderer
    }
}

// MARK: - Document

open class KMLDocument: KMLElement {
    open var overlays: [KMLOverlay] = []
    open var annotations: [KMLAnnotation] = []
    open var styles: Dictionary<String, KMLStyle> = [:]
    open var placemarks: [KMLPlacemark] = []
    public required init(_ element: AEXMLElement) {
        super.init(element)
        initStyle()
        placemarks = findElements(KMLPlacemark.self)
        for placemark in placemarks {
            if let foundStyle = findStyle(forPlacemark: placemark) {
                placemark.style = foundStyle
            }
        }
    }
    public convenience init? (url: URL, generateMapKitClasses: Bool=true) {
        var element: AEXMLElement?
        if let data = try? Data(contentsOf: url) {
            do {
                let xmlDoc = try AEXMLDocument(xml: data)
                element = xmlDoc.root["Document"]
            } catch _ {
                print("Could not parse XML.")
                return nil
            }
            self.init(element!, generateMapKitClasses:generateMapKitClasses)
        } else {
            print("Doesn't exist file at path - \(url)")
            let errorElement = AEXMLElement(name: "AEXMLError", value: "Doesn't exist file at path \(url)")
            errorElement.error = AEXMLError.parsingFailed
            self.init(errorElement, generateMapKitClasses:generateMapKitClasses)
        }
    }
    public convenience init(_ element: AEXMLElement, generateMapKitClasses: Bool) {
        self.init(element)
        if generateMapKitClasses {
            initOverlay()
            initAnnotation()
        }
    }
    open var isError: Bool {
        get {
            return self.children.count == 0
        }
    }
    fileprivate func initStyle() {
        if let _styles: [KMLStyle] = findElements(KMLStyle.self) {
            for style: KMLStyle in _styles {
                self.styles[style.styleId] = style
            }
        }
        if let _styles: [KMLStyleMap] = findElements(KMLStyleMap.self) {
            for style: KMLStyleMap in _styles {
                for (key, value): (String, String) in style.pairs {
                    style.addPairsRef(key, style: self.styles[value]!)
                }
                self.styles[style.styleId] = style
            }
        }
    }
    fileprivate func initOverlay() {
        for placemark: KMLPlacemark in placemarks {
            var overlays: [KMLOverlay] = []
            let polygons: [KMLPolygon] = placemark.findElements(KMLPolygon.self)
            for polygon: KMLPolygon in polygons {
                let poly = KMLOverlayPolygon(coordinates: &polygon.coordinates, count: UInt(polygon.coordinates.count))
                overlays.append(poly)
            }
            let lines: [KMLLineString] = placemark.findElements(KMLLineString.self)
            for line: KMLLineString in lines {
                let polyLine = KMLOverlayPolyline(coordinates: &line.coordinates, count: UInt(line.coordinates.count))
                overlays.append(polyLine)
            }
            for overlay: KMLOverlay in overlays {
                overlay.style = placemark.style
                self.overlays.append(overlay)
            }
        }
    }
    fileprivate func findStyle(forPlacemark placemark: KMLPlacemark) -> KMLStyle? {
        var foundStyle: KMLStyle?
        if let style: KMLStyle = styles[placemark.styleUrl] {
            foundStyle = style
        } else if let style: KMLStyle = placemark.findElement(KMLStyle.self) {
            foundStyle = style
        } else {
            foundStyle = nil
        }
        if let foundStyleMap = foundStyle as? KMLStyleMap,
            let normalStyle = foundStyleMap.normalStyle {
            foundStyle = normalStyle
        }
        return foundStyle
    }
    fileprivate func initAnnotation() {
        for pointPlacemark: KMLPlacemark in placemarks {
            if let point: KMLPoint = pointPlacemark.point {
                let annotation = KMLAnnotation(point.coordinates)
                annotation.title = pointPlacemark.name
                annotation.subtitle = pointPlacemark.description
                annotation.style = pointPlacemark.style
                self.annotations.append(annotation)
            }
        }
    }
    open class func parse(_ url: URL, generateMapKitClasses: Bool=true, callback: @escaping (KMLDocument) -> Void) {
        // Background Task
        let bgQueue = DispatchQueue.global(qos: .default)
        let mainQueue: DispatchQueue = DispatchQueue.main
        bgQueue.async(execute: {
            if let doc: KMLDocument = KMLDocument(url: url, generateMapKitClasses:generateMapKitClasses) {
                mainQueue.async(execute: {
                    callback(doc)
                })
            }
        })
    }
}

// MARK: Mapbox extensions for easy use
extension MGLShape {
    var alpha: CGFloat {
        if let annotation = self as? KMLOverlay {
            return annotation.renderer().alpha
        }
        return 1.0
    }
    var fillColor: UIColor? {
        if let annotation = self as? KMLOverlay {
            return annotation.style?.polyStyle?.color
        }
        return UIColor.blue
    }
    var strokeColor: UIColor? {
        if let annotation = self as? KMLOverlay {
            return annotation.style?.lineStyle?.color
        }
        return UIColor.black
    }
    var lineWidth: CGFloat {
        if let annotation = self as? KMLOverlay {
            if let width = annotation.style?.lineStyle?.width {
                return CGFloat(width)
            }
        }
        return 2.0
    }
}
