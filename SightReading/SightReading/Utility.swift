//
//  Utility.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/21.
//

import Foundation
import UIKit

class Utility {
    // rect is relative rect in imageView
    class func getAbsoluteRect(with rect: CGRect, in size: CGSize) -> CGRect {
        return CGRect(x: rect.origin.x * size.width,
                      y: rect.origin.y * size.height,
                      width: rect.size.width * size.width,
                      height: rect.size.height * size.height)
    }
    
    // rect is absolute rect in imageView
    class func getRelativeRect(with rect: CGRect, in size: CGSize) -> CGRect {
        return CGRect(x: rect.origin.x / size.width,
                      y: rect.origin.y / size.height,
                      width: rect.size.width / size.width,
                      height: rect.size.height / size.height)
    }
    
    class func getRect(with point1: CGPoint, and point2: CGPoint) -> CGRect {
        let x1 = point1.x
        let x2 = point2.x
        let y1 = point1.y
        let y2 = point2.y
        
        let x = min(x1, x2)
        let y = min(y1, y2)
        let width = abs(x1 - x2)
        let height = abs(y1 - y2)
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    class func getRootPath() -> String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
    
    class func hasNoteImage(for sheetImageName: String) -> Bool {
        if let rootPath = getRootPath() {
            let fullNoteImagePath = "\(rootPath)/\(sheetImageName)\(noteImageSubfix).png"
            return FileManager.default.fileExists(atPath: fullNoteImagePath)
        }
        return false
    }
    
    // scale "size" (keep the size.width/size.height not changed) to fit the given containerSize
    // return the frame of the inner rect (which has the same width/height as "size")
    class func fit(size: CGSize, into containerSize: CGSize) -> CGRect {
        var height = containerSize.height
        var width = containerSize.width
        let containerWHRatio = containerSize.width / containerSize.height
        let WHRatio = size.width / size.height
        if containerWHRatio > WHRatio { // outer container is more fat in horizontal direction, outer container and inner contaienr should have the same heigth
            width = containerSize.height * WHRatio
        } else { // outer container and inner container should have the same width
            height = containerSize.width / WHRatio
        }
        let x = (containerSize.width - width) / 2
        let y = (containerSize.height - height) / 2
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
