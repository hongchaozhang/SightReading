//
//  Utility.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/21.
//

import Foundation
import UIKit

enum MusicFileType {
    case json
    case sheet
    case note
}

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
    
    class func getFileName(musicName: String, pageIndex: Int, fileType: String, isSinglePageMusic: Bool) -> String {
        let pageIndexStr = isSinglePageMusic ? "" : "\(pageIndex+1)"
        return "\(musicName)\(pageIndexStr).\(fileType)"
    }
    
    class func getFileType(from fileName: String) -> MusicFileType {
        if fileName.hasSuffix(".json") {
            return .json
        }
        
        if fileName.hasSuffix("&-note.png") {
            return .note
        }else if fileName.hasSuffix(".png") {
            return .sheet
        }
        return .sheet
    }
    
    class func getUIPageIndex(from fileName: String) -> Int {
        var pageIndex = 1
        
        do {
            let numReg = try NSRegularExpression(pattern: "[0-9]", options: [])
            let matches = numReg.matches(in: fileName, options: [], range: NSRange(location: 0, length: fileName.count))
            if let match = matches.first {
                let nsRange = match.range(at: 0)
                if let range = Range(nsRange, in: fileName),
                   let index = Int(String(fileName.substring(with: range))) {
                    pageIndex = index
                }
            }
        } catch {
            
        }
        
        return pageIndex
    }
    
    class func sendRequest(apiPath: String, params: [String: String]?, onSuccess: ((Data?) -> Void)?, onFailure: ((Error?) -> Void)?) {
        let urlComponents = NSURLComponents(string: "http://localhost:3000/api/\(apiPath)")

        if let params = params {
            var queryItems = [URLQueryItem]()
            for (key, value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            urlComponents?.queryItems = queryItems
        }
        
        if let url = urlComponents?.url {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
//                print(response!)
                if (error == nil) {
                    onSuccess?(data)
                } else {
                    print(error.debugDescription)
                    onFailure?(error)
                }
            })

            task.resume()
        }
    }
    
}
