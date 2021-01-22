//
//  Mask.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import Foundation
import UIKit

class Mask: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        styleMask()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        styleMask()
    }
    
    private func styleMask() {
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.8).cgColor
        self.backgroundColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.8)
    }
}
