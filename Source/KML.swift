//
//  KML.swift
//
//  Created by Koki Ibukuro on 3/22/15.
//  Copyright (c) 2015 asus4. All rights reserved.
//

import Foundation
import MapKit
import AEXML

/**
KML format information
https://developers.google.com/kml/documentation/kmlreference
*/

// Supporting tags
public enum KMLTag: String {
    case Style = "Style"
    case StyleMap = "StyleMap"
    case PolyStyle = "PolyStyle"
    case LineStyle = "LineStyle"
    case MultiGeometry = "MultiGeometry"
    case Polygon = "Polygon"
    case LineString = "LineString"
    case Point = "Point"
    case Folder = "Folder"
    case Placemark = "Placemark"

    public var str: String {
        return self.rawValue
    }
}

public struct KMLConfig {
    // Able to replace with customized parser
    public static var tags: Dictionary<String, KMLElement.Type> = [
        KMLTag.Style.str : KMLStyle.self,
        KMLTag.StyleMap.str : KMLStyleMap.self,
        KMLTag.PolyStyle.str : KMLPolyStyle.self,
        KMLTag.LineStyle.str : KMLLineStyle.self,
        KMLTag.MultiGeometry.str : KMLMultiGeometry.self,
        KMLTag.Polygon.str : KMLPolygon.self,
        KMLTag.LineString.str : KMLLineString.self,
        KMLTag.Point.str : KMLPoint.self,
        KMLTag.Folder.str : KMLElement.self,
        KMLTag.Placemark.str : KMLPlacemark.self
    ]
}

// MARK: - Base classes
public class KMLElement {

    public var name: String = ""
    public var children: [KMLElement] = []

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            if child.name == "name" {
                self.name = child.stringValue
                continue
            }
            if let klass:KMLElement.Type = KMLConfig.tags[child.name] {
                children.append(klass(child))
            }
        }
    }

    class func parseCoordinates(element: AEXMLElement) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let lines: [String] = split(element.stringValue,
            allowEmptySlices: false,
            isSeparator: {$0 == "\n" || $0 == " "})
        for line: String in lines {
            let points: [String] = split(line, allowEmptySlices: false, isSeparator: {$0 == ","})
            assert(points.count >= 2, "points lenth is \(points)")
            coordinates.append(CLLocationCoordinate2DMake(atof(points[1]), atof(points[0])))
        }
        return coordinates
    }

    // return First emelent
    public func findElement<T:KMLElement>(type:T.Type) -> T! {
        for child: KMLElement in children {
            if let theChild: T = child as? T {
                return theChild
            }
            if let match: T = child.findElement(T.self) {
                return match
            }
        }
        return nil
    }

    // return All element
    public func findElements<T:KMLElement>(type:T.Type) -> [T]! {
        var elements: [T] = []
        for child: KMLElement in children {
            if let theChild: T = child as? T {
                elements.append(theChild)
            }
            if let matchs: [T] = child.findElements(T.self) {
                elements.extend(matchs)
            }
        }
        return elements
    }

    public func hasElement<T:KMLElement>(type:T.Type) -> Bool {
        for child: KMLElement in children {
            if child is T {
                return true
            }
            if child.hasElement(T.self) {
                return true
            }
        }
        return false
    }
}

// MARK: - Style

protocol KMLApplyStyle {
    func applyStyle(renderer: MKOverlayPathRenderer)
}

public class KMLStyle: KMLElement, KMLApplyStyle {

    var styleId: String = ""

    public required init(_ element: AEXMLElement) {
        if let _id: String = element.attributes["id"] as? String {
            styleId = _id
        }
        super.init(element)
    }

    func applyStyle(renderer: MKOverlayPathRenderer) {
        if let style: KMLPolyStyle = findElement(KMLPolyStyle.self) {
            style.applyStyle(renderer)
        }
        if let style: KMLLineStyle = findElement(KMLLineStyle.self) {
            style.applyStyle(renderer)
        }
    }
}

public class KMLStyleMap: KMLStyle {

    var pairs:Dictionary<String, String>
    var pairsRef:Dictionary<String, KMLStyle> = [:]

    public required init(_ element: AEXMLElement) {
        pairs = [:]
        for pair in element.children {
            let styleUrl: String = pair["styleUrl"].stringValue
            pairs[pair["key"].stringValue] = styleUrl.subString(1) // remove #
        }
        super.init(element)
    }

    func addPairsRef(key: String, style: KMLStyle) {
        pairsRef[key] = style
    }

    override func applyStyle(renderer: MKOverlayPathRenderer) {
        pairsRef["normal"]?.applyStyle(renderer)
    }
}

public class KMLPolyStyle: KMLElement, KMLApplyStyle {
    var color: UIColor = UIColor.blackColor()
    var colorMode: Int = 0
    var fill: Bool = true
    var outline: Bool = true

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "color":
                color = UIColor(kmlhex: child.stringValue)
            case "colorMode":
                colorMode = child.stringValue == "normal" ? 0 : 1
            case "fill":
                fill = child.boolValue
            case "outline":
                outline = child.boolValue
            default:
                break
            }
        }
        super.init(element)
    }

    func applyStyle(renderer: MKOverlayPathRenderer) {
        renderer.fillColor = self.color
    }
}

public class KMLLineStyle: KMLElement, KMLApplyStyle {
    var color: UIColor = UIColor.blackColor()
    var colorMode: Int = 0
    var width: Int = 1

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "color":
                color = UIColor(kmlhex: child.stringValue)
            case "colorMode":
                colorMode = child.stringValue == "normal" ? 0 : 1
            case "width":
                width = child.intValue
            default:
                break
            }
        }
        super.init(element)
    }

    func applyStyle(renderer: MKOverlayPathRenderer) {
        renderer.strokeColor = self.color
        renderer.lineWidth = CGFloat(self.width) * 0.5
    }
}

// MARK: - Drawings

public class KMLMultiGeometry: KMLElement {

}

public class KMLPolygon: KMLElement {

    public var tessellate: Bool = false
    public var coordinates: [CLLocationCoordinate2D] = []

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "tessellate":
                tessellate = child.intValue == 1 ? true : false
            case "outerBoundaryIs":
                coordinates = KMLElement.parseCoordinates(child["LinearRing"]["coordinates"])
            default:
                break
            }
        }
        super.init(element)
    }
}


public class KMLLineString: KMLElement {

    public var tessellate: Bool = false
    public var coordinates: [CLLocationCoordinate2D] = []

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "tessellate":
                tessellate = child.intValue == 1 ? true : false
            case "coordinates":
                coordinates = KMLElement.parseCoordinates(child)
            default:
                break
            }
        }
        super.init(element)
    }

}

public class KMLPoint: KMLElement {

    public var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "coordinates":
                coordinates = KMLPoint.parseCoordinate(child.stringValue)
            default:
                break
            }
        }
        super.init(element)
    }

    public class func parseCoordinate(str: String) -> CLLocationCoordinate2D {
        let points: [String] = split(str, allowEmptySlices: false, isSeparator: {$0 == ","})
        assert(points.count >= 2, "points lenth is \(points)")
        return CLLocationCoordinate2DMake(atof(points[1]), atof(points[0]))
    }
}


// MARK: - Placemark

public class KMLPlacemark: KMLElement {

    public var styleUrl: String = ""
    public var description: String = ""

    public required init(_ element: AEXMLElement) {
        styleUrl = element["styleUrl"].stringValue.subString(1) // remove #
        let _description: AEXMLElement = element["description"]
        if _description.name != AEXMLElement.errorElementName {
            description = _description.stringValue
        }
        super.init(element)
    }
}

// MARK: - MapKit bridge

public protocol KMLOverlay: MKOverlay {
    var style: KMLStyle? { get set }
    func renderer() -> MKOverlayRenderer
}

public class KMLAnnotation: NSObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D
    public var title: String!
    public var subtitle: String!

    init(_ coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

public class KMLOverlayPolygon: MKPolygon, KMLOverlay {

    public var style: KMLStyle? = nil

    public func renderer() -> MKOverlayRenderer {
        let renderer: MKPolygonRenderer = MKPolygonRenderer(polygon: self)

        if style != nil {
            style?.applyStyle(renderer)
        }
        else {
            renderer.fillColor = UIColor(red: 0.6, green: 1.0, blue: 0.5, alpha: 0.2)
            renderer.strokeColor = UIColor(red: 1.0, green: 0.6, blue: 0.5, alpha: 0.8)
            renderer.lineWidth = 2.0
        }

        return renderer
    }
}

public class KMLOverlayPolyline: MKPolyline, KMLOverlay {

    public var style: KMLStyle? = nil

    public func renderer() -> MKOverlayRenderer {
        let renderer: MKPolylineRenderer = MKPolylineRenderer(polyline: self)

        if style != nil {
            style?.applyStyle(renderer)
        }
        else {
            renderer.strokeColor = UIColor(red: 0.6, green: 0.6, blue: 1.0, alpha: 0.8)
            renderer.lineWidth = 2.0
        }

        return renderer
    }
}

// MARK: - Document

public class KMLDocument: KMLElement {

    public var overlays: [MKOverlay] = []
    public var annotations: [MKAnnotation] = []
    public var styles:Dictionary<String, KMLStyle> = [:]

    convenience init (url: NSURL) {
        var element: AEXMLElement?

        if let data = NSData(contentsOfURL: url) {
            var error: NSError?
            if let xmlDoc = AEXMLDocument(xmlData: data, error: &error) {
                element = xmlDoc.root["Document"]
            }
            else {
                println("Could not parse XML.\tdescription: \(error?.localizedDescription)\t info: \(error?.userInfo)")
            }
            self.init(element!)
        }
        else {
            println("Doesn't exist file at path - \(url)")
            self.init(AEXMLElement(AEXMLElement.errorElementName, value: "Doesn't exist file at path \(url)"))
        }

    }

    public required init(_ element: AEXMLElement) {
        super.init(element)
        initStyle()

        if let placemarks: [KMLPlacemark] = findElements(KMLPlacemark.self) {
            initOverlay(placemarks)
            initAnnotation(placemarks)
        }
    }

    public var isError: Bool {
        get {
            return self.children.count == 0
        }
    }

    private func initStyle() {
        if let _styles: [KMLStyle] = findElements(KMLStyle.self) {
            for style: KMLStyle in _styles {
                self.styles[style.styleId] = style
            }
        }
        if let _styles: [KMLStyleMap] = findElements(KMLStyleMap.self) {
            for style: KMLStyleMap in _styles {
                for (key: String, value: String) in style.pairs {
                    style.addPairsRef(key, style: self.styles[value]!)
                }
                self.styles[style.styleId] = style
            }
        }
    }

    private func initOverlay(placemarks: [KMLPlacemark]) {
        for placemark: KMLPlacemark in placemarks {

            var overlays: [KMLOverlay] = []

            let polygons: [KMLPolygon] = placemark.findElements(KMLPolygon.self)
            for poligon: KMLPolygon in polygons {
                overlays.append(KMLOverlayPolygon(coordinates: &poligon.coordinates, count: poligon.coordinates.count))
            }

            let lines: [KMLLineString] = placemark.findElements(KMLLineString.self)
            for line: KMLLineString in lines {
                overlays.append(KMLOverlayPolyline(coordinates: &line.coordinates, count: line.coordinates.count))
            }

            for overlay: KMLOverlay in overlays {
                if let style: KMLStyle = styles[placemark.styleUrl] {
                    overlay.style = style
                }
                else if let style: KMLStyle = placemark.findElement(KMLStyle.self) {
                    overlay.style = style
                }
                self.overlays.append(overlay)
            }
        }
    }

    private func initAnnotation(placemarks: [KMLPlacemark]) {
        for placemark: KMLPlacemark in placemarks {

            if let point: KMLPoint = placemark.findElement(KMLPoint.self) {

                let annotation = KMLAnnotation(point.coordinates)
                annotation.title = placemark.name
                annotation.subtitle = placemark.description

                self.annotations.append(annotation)
            }
        }
    }

    public class func parse(url: NSURL, callback: (KMLDocument) -> Void) {
        // Background Task
        let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let mainQueue: dispatch_queue_t = dispatch_get_main_queue()
        dispatch_async(bgQueue, {
            let doc: KMLDocument = KMLDocument(url: url)
            dispatch_async(mainQueue, {
                callback(doc)
            })
        })
    }
}

// MARK: - Private extensions

private extension String {
    func subString(from: Int) -> String {
        return self.substringFromIndex(advance(self.startIndex, from))
    }
}

// Referencing UIColor-Hex-Swift
// https://github.com/yeahdongcn/UIColor-Hex-Swift/blob/master/UIColorExtension.swift

private extension UIColor {
    convenience init(kmlhex: String) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0

        let scanner = NSScanner(string: kmlhex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexLongLong(&hexValue) {
            switch (count(kmlhex)) {
            case 3:
                red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue  = CGFloat(hexValue & 0x00F)              / 15.0
            case 4:
                red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                alpha = CGFloat(hexValue & 0x000F)             / 15.0
            case 6:
                red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
            case 8:
                // ABGR format
                alpha   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                blue = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                green  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                red = CGFloat(hexValue & 0x000000FF)         / 255.0
            default:
                print("Invalid RGB string, number should be either 3, 4, 6 or 8")
            }
        } else {
            println("Scan hex error")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
