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
    case IconStyle = "IconStyle"
    case BalloonStyle = "BalloonStyle"
    case MultiGeometry = "MultiGeometry"
    case Polygon = "Polygon"
    case LineString = "LineString"
    case Point = "Point"
    case Folder = "Folder"
    case Placemark = "Placemark"
    case Icon = "Icon"

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
        KMLTag.BalloonStyle.str : KMLBalloonStyle.self,
        KMLTag.MultiGeometry.str : KMLMultiGeometry.self,
        KMLTag.Polygon.str : KMLPolygon.self,
        KMLTag.LineString.str : KMLLineString.self,
        KMLTag.Point.str : KMLPoint.self,
        KMLTag.Folder.str : KMLElement.self,
        KMLTag.Placemark.str : KMLPlacemark.self,
        KMLTag.Icon.str : KMLIcon.self,
        KMLTag.IconStyle.str : KMLIconStyle.self
    ]
}

// MARK: - Base classes
open class KMLElement {

    open var name: String = ""
    open var children: [KMLElement] = []

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            if child.name == "name" {
                self.name = child.string
                continue
            }
            if let klass: KMLElement.Type = KMLConfig.tags[child.name] {
                children.append(klass.init(child))
            }
        }
    }

    class func parseCoordinates(_ element: AEXMLElement) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let lines: [String] =
            element.string.characters
                .split(omittingEmptySubsequences: true,
                       whereSeparator: ({$0 == "\n" || $0 == " "}))
                .map({ String($0) })
        for line: String in lines {
            let points: [String] =
                line.characters
                    .split(omittingEmptySubsequences: true,
                                      whereSeparator: ({$0 == ","}))
                    .map({ String($0) })
            assert(points.count >= 2, "points lenth is \(points)")
            coordinates.append(CLLocationCoordinate2DMake(atof(points[1]), atof(points[0])))
        }
        return coordinates
    }

    // return First emelent
    open func findElement<T: KMLElement>(_ type: T.Type) -> T! {
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
    open func findElements<T: KMLElement>(_ type: T.Type) -> [T]! {
        var elements: [T] = []
        for child: KMLElement in children {
            if let theChild: T = child as? T {
                elements.append(theChild)
            }
            if let matchs: [T] = child.findElements(T.self) {
                elements.append(contentsOf: matchs)
            }
        }
        return elements
    }

    open func hasElement<T: KMLElement>(_ type: T.Type) -> Bool {
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

public protocol KMLOverlayRenderer {
    var alpha: CGFloat { get set }
}
public protocol KMLOverlayPathRenderer: KMLOverlayRenderer {
    var fillColor: UIColor? { get set }
    var strokeColor: UIColor? { get set }
    var lineWidth: CGFloat { get set }
}

protocol KMLApplyStyle {
    func applyStyle(_ renderer: KMLOverlayRenderer)
}

open class KMLStyle: KMLElement, KMLApplyStyle {

    open var styleId: String = ""
    open var polyStyle: KMLPolyStyle?
    open var lineStyle: KMLLineStyle?
    open var iconStyle: KMLIconStyle?
    open var balloonStyle: KMLBalloonStyle?

    public required init(_ element: AEXMLElement) {
        super.init(element)
        if let _id: String = element.attributes["id"] {
            styleId = _id
            polyStyle = findElement(KMLPolyStyle.self)
            lineStyle = findElement(KMLLineStyle.self)
            iconStyle = findElement(KMLIconStyle.self)
            balloonStyle = findElement(KMLBalloonStyle.self)
        }
    }

    func applyStyle(_ renderer: KMLOverlayRenderer) {
        if let style: KMLPolyStyle = findElement(KMLPolyStyle.self) {
            style.applyStyle(renderer)
        }
        if let style: KMLLineStyle = findElement(KMLLineStyle.self) {
            style.applyStyle(renderer)
        }
    }
}

open class KMLStyleMap: KMLStyle {

    var pairs: Dictionary<String, String>
    var pairsRef: Dictionary<String, KMLStyle> = [:]
    var normalStyle: KMLStyle? {
        return pairsRef["normal"]
    }

    public required init(_ element: AEXMLElement) {
        pairs = [:]
        for pair in element.children {
            let styleUrl: String = pair["styleUrl"].string
            pairs[pair["key"].string] = styleUrl.subString(1) // remove #
        }
        super.init(element)
    }

    func addPairsRef(_ key: String, style: KMLStyle) {
        pairsRef[key] = style
    }

    override func applyStyle(_ renderer: KMLOverlayRenderer) {
        normalStyle?.applyStyle(renderer)
    }
}

open class KMLColorStyleGroup: KMLElement {
    open var color: UIColor = UIColor.black
    open var colorMode: Int = 0
    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "color":
                color = UIColor(kmlhex: child.string)
            case "colorMode":
                colorMode = child.string == "normal" ? 0 : 1
            default:
                break
            }
        }
        super.init(element)
    }
}

open class KMLPolyStyle: KMLColorStyleGroup, KMLApplyStyle {
    open var fill: Bool = true
    open var outline: Bool = true

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "fill":
                fill = child.bool
            case "outline":
                outline = child.bool
            default:
                break
            }
        }
        super.init(element)
    }

    func applyStyle(_ renderer: KMLOverlayRenderer) {
        if var renderer = renderer as? KMLOverlayPathRenderer {
            renderer.fillColor = self.color
        }
    }
}

open class KMLLineStyle: KMLColorStyleGroup, KMLApplyStyle {
    open var width: Double = 1

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "width":
                width = child.double
            default:
                break
            }
        }
        super.init(element)
    }

    func applyStyle(_ renderer: KMLOverlayRenderer) {
        if var renderer = renderer as? KMLOverlayPathRenderer {
            renderer.strokeColor = self.color
            renderer.lineWidth = CGFloat(self.width) * 0.5
        }
    }
}

open class KMLIconStyle: KMLColorStyleGroup {
    open var scale: Double = 1.0
    open var heading: Double = 0.0
    open var icon: KMLIcon?

    public required init(_ element: AEXMLElement) {
        super.init(element)
        for child: AEXMLElement in element.children {
            switch child.name {
            case "scale":
                scale = child.double
            case "heading":
                heading = child.double
            default:
                break
            }
        }
        icon = findElement(KMLIcon.self)
    }

}

open class KMLBalloonStyle: KMLElement {
    open var bgColor: UIColor = UIColor.black
    open var textColor: UIColor = UIColor.black
    open var text: String = ""
    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "bgColor":
                bgColor = UIColor(kmlhex: child.string)
            case "textColor":
                textColor = UIColor(kmlhex: child.string)
            case "text":
                text = child.string
            default:
                break
            }
        }
        super.init(element)
    }

}

open class KMLIcon: KMLElement {
    open var href: String!
    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "href":
                href = child.string
            default:
                break
            }
        }
        super.init(element)
    }

}

// MARK: - Drawings
open class KMLMultiGeometry: KMLElement {

}

open class KMLPolygon: KMLElement {

    open var tessellate: Bool = false
    open var coordinates: [CLLocationCoordinate2D]
    open var outerBoundaryCoordinates: [CLLocationCoordinate2D] = []
    open var innerBoundariesCoordinates: [[CLLocationCoordinate2D]] = []

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "tessellate":
                tessellate = child.int == 1 ? true : false
            case "outerBoundaryIs":
                outerBoundaryCoordinates = KMLElement.parseCoordinates(child["LinearRing"]["coordinates"])
            case "innerBoundaryIs":
                innerBoundariesCoordinates.append(KMLElement.parseCoordinates(child["LinearRing"]["coordinates"]))
            default:
                break
            }
        }
        coordinates = outerBoundaryCoordinates
        super.init(element)
    }
}

open class KMLLineString: KMLElement {

    open var tessellate: Bool = false
    open var coordinates: [CLLocationCoordinate2D] = []

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "tessellate":
                tessellate = child.int == 1 ? true : false
            case "coordinates":
                coordinates = KMLElement.parseCoordinates(child)
            default:
                break
            }
        }
        super.init(element)
    }

}

open class KMLPoint: KMLElement {

    open var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)

    public required init(_ element: AEXMLElement) {
        for child: AEXMLElement in element.children {
            switch child.name {
            case "coordinates":
                coordinates = KMLPoint.parseCoordinate(child.string)
            default:
                break
            }
        }
        super.init(element)
    }

    open class func parseCoordinate(_ str: String) -> CLLocationCoordinate2D {
        let points: [String] = str.characters.split(omittingEmptySubsequences: true,
                                                    whereSeparator: {$0 == ","}).map { String($0) }
        assert(points.count >= 2, "points length is \(points)")
        return CLLocationCoordinate2DMake(atof(points[1]), atof(points[0]))
    }
}

// MARK: - Placemark
open class KMLPlacemark: KMLElement {
    open var styleUrl: String = ""
    open var description: String = ""
    open var point: KMLPoint?
    open var lineString: KMLLineString?
    open var polygon: KMLPolygon?
    open var style: KMLStyle?

    public required init(_ element: AEXMLElement) {
        styleUrl = element["styleUrl"].string.subString(1) // remove #
        let _description: AEXMLElement = element["description"]
        if element.error == nil {
            description = _description.string
        }
        super.init(element)

        if let pointGeometry = findElement(KMLPoint.self) {
            point = pointGeometry
        } else if let lineStringGeometry = findElement(KMLLineString.self) {
            lineString = lineStringGeometry
        } else if let polygonGeometry = findElement(KMLPolygon.self) {
            polygon = polygonGeometry
        }
    }
}

// MARK: - Private extensions

private extension String {
    func subString(_ from: Int) -> String {
        return self.substring(from: self.characters.index(self.startIndex, offsetBy: from))
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

        let scanner = Scanner(string: kmlhex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch kmlhex.characters.count {
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
                print("Invalid RGB string, number should be either 3, 4, 6 or 8", terminator: "")
            }
        } else {
            print("Scan hex error")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
