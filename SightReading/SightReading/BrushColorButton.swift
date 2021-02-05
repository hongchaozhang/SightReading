//
//  ColorButton.swift
//  SightReading
//
//  Created by Zhang, Hongchao on 2021/2/4.
//

import Foundation
import UIKit

class BrushColorButton: UIButton {
    var _selectedColor = UIColor.blue
    @IBInspectable var selectedColor: UIColor {
        get {
            return _selectedColor
        }
        set {
            _selectedColor = newValue
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let colorPath = UIBezierPath(arcCenter: CGPoint(x: rect.width/2, y: rect.height/2),
                                     radius: rect.size.width/2 - 7.5,
            startAngle: 0,
            endAngle: 7,
            clockwise: true)
        self.selectedColor.setFill()
        colorPath.fill()
        
        let borderPath = UIBezierPath(ovalIn: rect.insetBy(dx: 7.5, dy: 7.5))
        borderPath.lineWidth = 2.0
        UIColor.lightGray.setStroke()
        
        borderPath.stroke()
    }
}
