//
//  Polygons.swift
//  updown
//
//  Created by Willie Liwa Johnson on 4/3/22.
//

import Foundation
import SpriteKit

func CGPolygonPath(radius: CGFloat, vertices: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let angle = 360.0 / vertices
    var i = CGFloat(1.0); while i <= vertices {
        let degrees = angle * i + 45.0
        let radians = degrees * .pi / 180.0
        let point = CGPoint(
            x: cos(radians) * radius,
            y: sin(radians) * radius
        )
        if i == 1.0 {
            path.move(to: point)
        } else {
            path.addLine(to: point)
        }
        i += 1.0
    }
    path.closeSubpath()
    return path
}

extension SKShapeNode {
    public convenience init(polygonOfRadius r: CGFloat, vertices v: Int) {
        self.init(path: CGPolygonPath(radius: r, vertices: CGFloat(v)))
    }
    public convenience init(triangleOfRadius r: CGFloat) {
        self.init(path: CGPolygonPath(radius: r, vertices: 3.0))
    }
}
