//
//  CacheManager.swift
//  SightReading
//
//  Created by Zhang, Hongchao on 2023/5/15.
//

import Foundation
import UIKit

class CacheManager {
    static let shared = CacheManager()
    
    private let cacheDirectory: String
    private let musicNamesKey = "cachedMusicNames"
    private let allTagsKey = "cachedAllTags"
    private let musicTagsPrefix = "tags_"
    private let cacheStatusKey = "cacheStatus"
    
    private init() {
        // 创建缓存目录
        if let documentsDirectory = Utility.getRootPath() {
            cacheDirectory = "\(documentsDirectory)/cache"
            if !FileManager.default.fileExists(atPath: cacheDirectory) {
                try? FileManager.default.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            }
        } else {
            cacheDirectory = ""
        }
    }
    
    // 检查是否有完整的缓存
    func hasCachedData() -> Bool {
        return UserDefaults.standard.bool(forKey: cacheStatusKey)
    }
    
    // 将数据状态标记为已缓存
    func setDataCached() {
        UserDefaults.standard.set(true, forKey: cacheStatusKey)
    }
    
    // 将数据状态标记为未缓存
    func clearCacheStatus() {
        UserDefaults.standard.set(false, forKey: cacheStatusKey)
    }
    
    // 获取所有缓存的音乐名称
    func getCachedMusicNames() -> [String]? {
        return UserDefaults.standard.stringArray(forKey: musicNamesKey)
    }
    
    // 缓存所有音乐名称
    func cacheMusicNames(_ musicNames: [String]) {
        UserDefaults.standard.set(musicNames, forKey: musicNamesKey)
    }
    
    // 获取所有缓存的标签
    func getCachedAllTags() -> [String]? {
        return UserDefaults.standard.stringArray(forKey: allTagsKey)
    }
    
    // 缓存所有标签
    func cacheAllTags(_ tags: [String]) {
        UserDefaults.standard.set(tags, forKey: allTagsKey)
    }
    
    // 获取音乐的标签
    func getCachedTagsForMusic(musicName: String) -> [String]? {
        return UserDefaults.standard.stringArray(forKey: "\(musicTagsPrefix)\(musicName)")
    }
    
    // 缓存音乐的标签
    func cacheTagsForMusic(musicName: String, tags: [String]) {
        UserDefaults.standard.set(tags, forKey: "\(musicTagsPrefix)\(musicName)")
    }
    
    // 清除单个音乐的标签缓存
    func clearCachedTagsForMusic(musicName: String) {
        UserDefaults.standard.removeObject(forKey: "\(musicTagsPrefix)\(musicName)")
    }
    
    // 获取音乐文件的缓存路径
    func getCachedFilePath(fileName: String) -> String {
        return "\(cacheDirectory)/\(fileName)"
    }
    
    // 检查文件是否已缓存
    func isFileCached(fileName: String) -> Bool {
        let filePath = getCachedFilePath(fileName: fileName)
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    // 缓存音乐文件
    func cacheFile(data: Data, fileName: String) -> Bool {
        let filePath = getCachedFilePath(fileName: fileName)
        return FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
    }
    
    // 从缓存中读取音乐文件
    func getCachedFile(fileName: String) -> Data? {
        let filePath = getCachedFilePath(fileName: fileName)
        return FileManager.default.contents(atPath: filePath)
    }
    
    // 缓存图片
    func cacheImage(image: UIImage, fileName: String) -> Bool {
        guard let data = image.pngData() else { return false }
        return cacheFile(data: data, fileName: fileName)
    }
    
    // 从缓存中获取图片
    func getCachedImage(fileName: String) -> UIImage? {
        guard let data = getCachedFile(fileName: fileName) else { return nil }
        return UIImage(data: data)
    }
    
    // 清除所有缓存
    func clearAllCache() {
        // 清除UserDefaults中的缓存信息
        UserDefaults.standard.removeObject(forKey: musicNamesKey)
        UserDefaults.standard.removeObject(forKey: allTagsKey)
        
        // 清除所有音乐的标签缓存
        if let musicNames = getCachedMusicNames() {
            for musicName in musicNames {
                clearCachedTagsForMusic(musicName: musicName)
            }
        }
        
        // 清除缓存目录中的所有文件
        if FileManager.default.fileExists(atPath: cacheDirectory) {
            try? FileManager.default.removeItem(atPath: cacheDirectory)
            try? FileManager.default.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        clearCacheStatus()
    }
} 