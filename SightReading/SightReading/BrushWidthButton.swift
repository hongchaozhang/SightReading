//
//  BrushWidthButton.swift
//  SightReading
//
//  Created by Zhang, Hongchao on 2021/2/4.
//

import Foundation
import UIKit

class BrushWidthButton: UIButton {
    var _selectedWidth = CGFloat(1.0)
    @IBInspectable var selectedWidth: CGFloat {
        get {
            return _selectedWidth
        }
        set {
            _selectedWidth = newValue
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let colorPath = UIBezierPath(arcCenter: CGPoint(x: rect.width/2, y: rect.height/2),
            radius: self.selectedWidth/2,
            startAngle: 0,
            endAngle: 7,
            clockwise: true)
        UIColor.blue.setFill()
        colorPath.fill()
        
        let borderPath = UIBezierPath(ovalIn: rect.insetBy(dx: 7.5, dy: 7.5))
        borderPath.lineWidth = 2.0
        UIColor.lightGray.setStroke()
        
        borderPath.stroke()
    }
}
