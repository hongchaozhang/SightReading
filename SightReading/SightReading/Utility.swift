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
//        if let rootPath = getRootPath() {
//            let fullNoteImagePath = "\(rootPath)/\(sheetImageName)\(noteImageSubfix).png"
//            return FileManager.default.fileExists(atPath: fullNoteImagePath)
//        }
        return false
        
        // need enhance GET /api/allMusicNames to return if a music has note images or not.
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
        } else if fileName.hasSuffix(".png") || fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg") {
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
    
    class func convertBarFramesToString(_ barFrames: [Int: CGRect]) -> [String: [String]] {
        var newBarFrames = [String: [String]]()
        for (key, value) in barFrames {
            let newKey = String(key)
            var newValue = [String]()
            newValue.append(value.origin.x.description)
            newValue.append(value.origin.y.description)
            newValue.append(value.size.width.description)
            newValue.append(value.size.height.description)
            newBarFrames[newKey] = newValue
        }
        
        return newBarFrames
    }
    
    class func getURL(apiPath: String, params: [String: String]?) -> URL? {
//        let urlComponents = NSURLComponents(string: "http://175.24.174.227:8081/api/\(apiPath)") // tecent lighthouse server Zhang Hongchao
//        let urlComponents = NSURLComponents(string: "http://10.23.35.26:8081/api/\(apiPath)") // mstr vra server
//        let urlComponents = NSURLComponents(string: "http://localhost:8081/api/\(apiPath)") // localhost server
        let urlComponents = NSURLComponents(string: "http://1.117.142.222:8081/api/\(apiPath)") // tecent lighthouse server Zhang Kaiyun

        if let params = params {
            var queryItems = [URLQueryItem]()
            for (key, value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            urlComponents?.queryItems = queryItems
        }
        
        return urlComponents?.url
    }
    
    class func sendRequest(apiPath: String, httpMethod: String = "GET", params: [String: String]? = nil, onSuccess: ((Data?) -> Void)? = nil, onFailure: ((Error?) -> Void)? = nil) {
        if let url = Utility.getURL(apiPath: apiPath, params: params) {
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod

            let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
//                print(response!)
                if let httpResponse = response as? HTTPURLResponse {
                    let code = httpResponse.statusCode
                    if code == 404 || code == 400 || code == 500 {
                        onFailure?(error)
                    } else {
                        onSuccess?(data)
                    }
                } else {
                    if (error == nil) {
                        onSuccess?(data)
                    } else {
                        print(error.debugDescription)
                        onFailure?(error)
                    }
                }

            })

            task.resume()
        }
    }

    
    class func uploadFileToServer(fileData: Data, fileName: String, musicFileType: MusicFileType, onSuccess: ((Data?) -> Void)? = nil, onFailure: ((Error?) -> Void)? = nil) {
        guard let url  = Utility.getURL(apiPath: "uploadFile", params: [fileNameKey: fileName]) else { return };
            var request = URLRequest(url: url)
        let fileType = musicFileType == .json ? ".json" : (musicFileType == .note ? ".png" : ".jpg")
            let boundary:String = "Boundary-\(UUID().uuidString)"
            
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            body.append("--\(boundary)\r\n");
            body.append("Content-Disposition: form-data; name=uploadFile; filename=\(fileName)\r\n");
            body.append("Content-Type: \(fileType)\r\n\r\n");
            body.append(fileData);
            body.append("\r\n");
            body.append("--\(boundary)--\r\n")
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, res, error) in
                if let error = error {
                    print(error.localizedDescription);
                    return;
                };
                guard let data = data else {
                    print(res.debugDescription);
                    return;
                };
                do {
                    guard
                        let json    = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
                        let success = json["success"] as? Int, success == 1,
                        let msg     = json["msg"] as? String
                        else { return };
                    DispatchQueue.main.async {
                        //
                    };
                } catch let error {
                    print(error.localizedDescription);
                };
            })
            task.resume()
        }
    
}

extension Data{
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
