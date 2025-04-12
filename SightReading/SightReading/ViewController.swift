//
//  ViewController.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import UIKit

class ViewController: UIViewController {
    private let allTagConstant = "All"
    private let allTagsKey = "ALL_TAGS"
    private var allTags = [String]()
    private var allFileTags = [String: [String]]()
    
    private var allTagsForSelector = [String]()
    
    @IBOutlet weak var fileTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tagSelector: UITextField!
    private var tagPickerView: UIPickerView!
    
    private let fileTableViewCellIdentifier = "FILE_TABLE_VIEW_CELL"
    private let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    
    private var allFileNames = [String]()
    private var filtedFileNames: [String] {
        let fileNamesByTagFilter = allFileNames.filter { (fileName) -> Bool in
            if let selectedTag = tagSelector.text {
                if selectedTag == allTagConstant {
                    return true
                } else {
                    if let tags = allFileTags[fileName] {
                        if tags.contains(selectedTag) {
                            return true
                        } else {
                            return false
                        }
                    }
                }
            }
            return false
        }
        let filteredFileNamesBySearchKeyword = fileNamesByTagFilter.filter { (fileName) -> Bool in
            if let keyword = searchBar.searchTextField.text, keyword != "" {
                if fileName.lowercased().contains(keyword.lowercased()) {
                    return true
                }
                if let tags = allFileTags[fileName] {
                    for tag in tags {
                        if tag.lowercased().contains(keyword.lowercased()) {
                            return true
                        }
                    }
                }
                return false
            }
            return true
        }
        
        return filteredFileNamesBySearchKeyword
    }

    private var isCaching = false // 是否正在进行缓存操作

    override func viewDidLoad() {
        super.viewDidLoad()
        fileTableView.delegate = self
        fileTableView.dataSource = self
        setupTagSelector()
        setupSearchBar()
        setupCacheButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRemoteFileNamesAndTags()
        updateCacheButtonStatus()
    }
    
    private func setupTagSelector() {
        tagPickerView = UIPickerView()
        tagPickerView.delegate = self
        tagPickerView.dataSource = self
        tagSelector.inputView = tagPickerView
        
        tagSelector.text = allTagConstant
        tagPickerView.selectRow(0, inComponent: 0, animated: false)
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
    }
    
    // MARK: - load resources
    
    private func loadRemoteFileNamesAndTags() {
        func onSuccess(_ data: Data?) {
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, [String]>
//                print(json)
                if let allFileNames = json["allMusicNames"] {
                    self.allFileNames = allFileNames
                    self.allFileNames.sort()
                    self.loadRemoteTags()
                    DispatchQueue.main.async {
                        self.fileTableView.reloadData()
                        self.updateCacheButtonStatus()
                    }
                }
            } catch {
                print("error")
            }
        }
        
        Utility.sendRequest(apiPath: "allMusicNames", onSuccess: onSuccess(_:))
    }
    
    private func loadRemoteTags() {
        func onSuccess(_ data: Data?) {
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, [String]>
                DispatchQueue.main.async {
                    if let allTags = json[self.allTagsKey] {
                        self.allTags = allTags.sorted()
                        self.allTagsForSelector = allTags.sorted()
                        self.allTagsForSelector.insert(self.allTagConstant, at: 0)
                    }
                    for fileName in self.allFileNames {
                        if let fileTags = json[fileName] {
                            self.allFileTags[fileName] = fileTags.sorted()
                        }
                    }
                    self.fileTableView.reloadData()
                }
            } catch {
                print("error")
            }
        }
        
        Utility.sendRequest(apiPath: "allTags", onSuccess: onSuccess(_:))
    }
    
    // MARK: - button callbacks
    @IBAction func addNewTapped(_ sender: UIBarButtonItem) {
        if let addNewVC = storyBoard.instantiateViewController(identifier: "AddNew") as? AddNewViewController {
            navigationController?.pushViewController(addNewVC, animated: true)
        }
    }
    
    // 设置缓存按钮
    private func setupCacheButton() {
        let cacheButton = UIBarButtonItem(title: "缓存全部", style: .plain, target: self, action: #selector(cacheAllData))
        navigationItem.leftBarButtonItem = cacheButton
        
        // 更新按钮状态
        updateCacheButtonStatus()
    }

    // 更新缓存按钮状态
    private func updateCacheButtonStatus() {
        if CacheManager.shared.hasCachedData() {
            navigationItem.leftBarButtonItem?.title = "已缓存"
            navigationItem.leftBarButtonItem?.isEnabled = false
        } else {
            navigationItem.leftBarButtonItem?.title = "缓存全部"
            navigationItem.leftBarButtonItem?.isEnabled = true
        }
    }

    // 一键缓存所有数据
    @objc private func cacheAllData() {
        if isCaching {
            return
        }
        
        // 显示提示
        let alertController = UIAlertController(title: "缓存音乐", message: "是否确定缓存所有音乐数据？这将下载所有音乐文件，可能会消耗较多流量。", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] _ in
            self?.startCachingAllData()
        }))
        
        present(alertController, animated: true, completion: nil)
    }

    // 开始缓存所有数据
    private func startCachingAllData() {
        // 防止重复操作
        if isCaching {
            return
        }
        
        isCaching = true
        
        // 显示加载提示
        let loadingAlert = UIAlertController(title: "正在缓存", message: "请稍候...\n0%", preferredStyle: .alert)
        
        // 添加取消按钮
        loadingAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { [weak self] _ in
            self?.isCaching = false
            // 取消所有正在进行的网络请求
            URLSession.shared.getAllTasks { tasks in
                tasks.forEach { $0.cancel() }
            }
        }))
        
        present(loadingAlert, animated: true, completion: nil)
        
        // 清除旧缓存
        CacheManager.shared.clearAllCache()
        
        // 设置超时定时器
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.isCaching {
                self.isCaching = false
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        let timeoutAlert = UIAlertController(title: "缓存超时", message: "下载过程耗时过长，请检查网络连接后重试", preferredStyle: .alert)
                        timeoutAlert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
                        self.present(timeoutAlert, animated: true, completion: nil)
                    }
                }
            }
        }
        
        // 更新进度显示
        func updateProgress(_ progress: Float, _ message: String = "请稍候...") {
            DispatchQueue.main.async {
                let percentage = Int(progress * 100)
                loadingAlert.message = "\(message)\n\(percentage)%"
            }
        }
        
        // 缓存所有音乐名称
        updateProgress(0.05, "获取音乐列表...")
        cacheMusicNames { [weak self] success in
            guard let self = self else { 
                timeoutTimer.invalidate()
                return 
            }
            
            if success {
                // 缓存所有标签
                updateProgress(0.1, "获取标签信息...")
                self.cacheAllTags { success in
                    if success {
                        // 缓存所有音乐文件
                        updateProgress(0.15, "开始下载音乐文件...")
                        
                        // 设置进度回调
                        self.setProgressCallback { progress in
                            // 将进度从0.15到1.0范围映射
                            let mappedProgress = 0.15 + progress * 0.85
                            updateProgress(mappedProgress, "下载音乐文件...")
                        }
                        
                        self.cacheAllMusicFiles { success in
                            self.clearProgressCallback()
                            timeoutTimer.invalidate()
                            DispatchQueue.main.async {
                                self.isCaching = false
                                loadingAlert.dismiss(animated: true) {
                                    // 显示缓存结果
                                    let resultAlert = UIAlertController(
                                        title: success ? "缓存成功" : "缓存失败",
                                        message: success ? "所有音乐数据已缓存完成" : "部分数据缓存失败，请重试",
                                        preferredStyle: .alert
                                    )
                                    resultAlert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
                                    self.present(resultAlert, animated: true, completion: nil)
                                    
                                    if success {
                                        // 标记缓存状态
                                        CacheManager.shared.setDataCached()
                                        // 更新按钮状态
                                        self.updateCacheButtonStatus()
                                    }
                                }
                            }
                        }
                    } else {
                        timeoutTimer.invalidate()
                        DispatchQueue.main.async {
                            self.isCaching = false
                            loadingAlert.dismiss(animated: true) {
                                let failAlert = UIAlertController(title: "缓存失败", message: "标签信息缓存失败", preferredStyle: .alert)
                                failAlert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
                                self.present(failAlert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            } else {
                timeoutTimer.invalidate()
                DispatchQueue.main.async {
                    self.isCaching = false
                    loadingAlert.dismiss(animated: true) {
                        let failAlert = UIAlertController(title: "缓存失败", message: "音乐名称缓存失败", preferredStyle: .alert)
                        failAlert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
                        self.present(failAlert, animated: true, completion: nil)
                    }
                }
            }
        }
    }

    // 进度回调
    private var progressCallback: ((Float) -> Void)?
    
    private func setProgressCallback(_ callback: @escaping (Float) -> Void) {
        progressCallback = callback
    }
    
    private func clearProgressCallback() {
        progressCallback = nil
    }

    // 缓存所有音乐名称
    private func cacheMusicNames(completion: @escaping (Bool) -> Void) {
        func onSuccess(_ data: Data?) {
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, [String]>
                if let allFileNames = json["allMusicNames"] {
                    CacheManager.shared.cacheMusicNames(allFileNames)
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print("Error caching music names: \(error)")
                completion(false)
            }
        }
        
        func onFailure(_ error: Error?) {
            print("Failed to get music names: \(String(describing: error))")
            completion(false)
        }
        
        Utility.sendRequest(apiPath: "allMusicNames", onSuccess: onSuccess, onFailure: onFailure)
    }

    // 缓存所有标签
    private func cacheAllTags(completion: @escaping (Bool) -> Void) {
        func onSuccess(_ data: Data?) {
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, [String]>
                if let allTags = json[allTagsKey] {
                    CacheManager.shared.cacheAllTags(allTags)
                    
                    // 缓存每个音乐的标签
                    if let musicNames = CacheManager.shared.getCachedMusicNames() {
                        for musicName in musicNames {
                            if let musicTags = json[musicName] {
                                CacheManager.shared.cacheTagsForMusic(musicName: musicName, tags: musicTags)
                            }
                        }
                    }
                    
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print("Error caching tags: \(error)")
                completion(false)
            }
        }
        
        func onFailure(_ error: Error?) {
            print("Failed to get tags: \(String(describing: error))")
            completion(false)
        }
        
        Utility.sendRequest(apiPath: "allTags", onSuccess: onSuccess, onFailure: onFailure)
    }

    // 缓存所有音乐文件
    private func cacheAllMusicFiles(completion: @escaping (Bool) -> Void) {
        guard let musicNames = CacheManager.shared.getCachedMusicNames(), !musicNames.isEmpty else {
            completion(false)
            return
        }
        
        // 分批处理音乐，每批10个
        let batchSize = 10
        let batches = stride(from: 0, to: musicNames.count, by: batchSize).map {
            Array(musicNames[$0..<min($0 + batchSize, musicNames.count)])
        }
        
        var currentBatchIndex = 0
        var hasError = false
        
        func processBatch() {
            if currentBatchIndex >= batches.count {
                // 所有批次处理完毕
                completion(!hasError)
                return
            }
            
            let currentBatch = batches[currentBatchIndex]
            let group = DispatchGroup()
            
            for musicName in currentBatch {
                group.enter()
                
                func onMusicInfoSuccess(_ data: Data?) {
                    do {
                        if let data = data {
                            // 缓存音乐信息文件
                            let jsonFileName = "\(musicName)_fileInfo.json"
                            _ = CacheManager.shared.cacheFile(data: data, fileName: jsonFileName)
                            
                            // 解析音乐文件信息
                            let fileInfoDic = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                            
                            if let musicFileNames = fileInfoDic[musicFileNamesKey] as? [String] {
                                // 创建子任务组来下载该音乐的所有文件
                                let subGroup = DispatchGroup()
                                
                                // 每个音乐只下载最多5个文件，防止过多请求
                                let filesToDownload = Array(musicFileNames.prefix(5))
                                
                                for fileName in filesToDownload {
                                    subGroup.enter()
                                    
                                    func onFileSuccess(_ fileData: Data?) {
                                        if let fileData = fileData {
                                            _ = CacheManager.shared.cacheFile(data: fileData, fileName: fileName)
                                        }
                                        subGroup.leave()
                                    }
                                    
                                    func onFileFailure(_ error: Error?) {
                                        print("Failed to download file \(fileName): \(String(describing: error))")
                                        hasError = true
                                        subGroup.leave()
                                    }
                                    
                                    // 先检查缓存
                                    if CacheManager.shared.isFileCached(fileName: fileName) {
                                        subGroup.leave()
                                    } else {
                                        Utility.sendRequest(apiPath: "musicFile", params: ["musicFileName": fileName], onSuccess: onFileSuccess, onFailure: onFileFailure)
                                    }
                                }
                                
                                // 不要在这里等待，而是使用通知
                                subGroup.notify(queue: .global()) {
                                    group.leave()
                                }
                            } else {
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    } catch {
                        print("Error processing music info: \(error)")
                        hasError = true
                        group.leave()
                    }
                }
                
                func onMusicInfoFailure(_ error: Error?) {
                    print("Failed to get music info for \(musicName): \(String(describing: error))")
                    hasError = true
                    group.leave()
                }
                
                // 先检查缓存
                let jsonFileName = "\(musicName)_fileInfo.json"
                if CacheManager.shared.isFileCached(fileName: jsonFileName) {
                    if let cachedData = CacheManager.shared.getCachedFile(fileName: jsonFileName) {
                        onMusicInfoSuccess(cachedData)
                    } else {
                        group.leave()
                    }
                } else {
                    Utility.sendRequest(apiPath: "musicFileInfo", params: ["musicName": musicName], onSuccess: onMusicInfoSuccess, onFailure: onMusicInfoFailure)
                }
            }
            
            // 当前批次处理完毕后，处理下一批
            group.notify(queue: .global()) {
                currentBatchIndex += 1
                
                // 计算进度并通知
                let progress = Float(currentBatchIndex) / Float(batches.count)
                DispatchQueue.main.async {
                    self.progressCallback?(progress)
                    print("批次 \(currentBatchIndex)/\(batches.count) 完成 - 进度: \(Int(progress * 100))%")
                }
                
                // 处理下一批
                processBatch()
            }
        }
        
        // 开始处理第一批
        processBatch()
    }

    private func deleteItem(at indexPath: IndexPath) {
        let musicName = filtedFileNames[indexPath.row]
        
        if let indexInAllFileNames = allFileNames.firstIndex(of: musicName) {
            allFileNames.remove(at: indexInAllFileNames)
        }
        fileTableView.deleteRows(at: [indexPath], with: .fade)
        fileTableView.reloadData()
        
        Utility.sendRequest(apiPath: "music", httpMethod: "DELETE", params: ["musicName": musicName])
        
        // 清除缓存状态
        clearLocalCacheStatus()
    }

    // 清除本地缓存状态
    private func clearLocalCacheStatus() {
        CacheManager.shared.clearCacheStatus()
        updateCacheButtonStatus()
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < filtedFileNames.count else {
            print("错误：选择了超出范围的行")
            return
        }
        
        let musicName = filtedFileNames[indexPath.row]
        let playVC = storyBoard.instantiateViewController(identifier: "Play") as! PlayViewController
        playVC.navigationItem.title = musicName
        
        // 取消选中状态
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationController?.pushViewController(playVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    private func editTags(for indexPath: IndexPath) {
        if let tagVCOption = storyboard?.instantiateViewController(identifier: "Tags"),
           let tagVC = tagVCOption as? EditTagViewController {
            tagVC.fileName = filtedFileNames[indexPath.row]
            tagVC.allTags = allTags
            if let fileTags = allFileTags[filtedFileNames[indexPath.row]] {
                tagVC.selectedTags = fileTags
            }
            tagVC.delegate = self
            self.present(tagVC, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.deleteItem(at: indexPath)
        }
        let editAction = UITableViewRowAction(style: .default, title: "Edit Tags") { (action, indexPath) in
            self.editTags(for: indexPath)
        }
        editAction.backgroundColor = UIColor(displayP3Red: 60/255, green: 148/255, blue: 1.0, alpha: 1.0)
        deleteAction.backgroundColor = .red

        return [deleteAction, editAction]
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    private func getTagListString(for fileName: String) -> String {
        var cellText = ""
        if let tags = allFileTags[fileName] {
            for tag in tags {
                cellText += tag
                if tags.last != tag {
                    cellText += " | "
                }
            }
        }
        
        return cellText
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtedFileNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = fileTableView.dequeueReusableCell(withIdentifier: fileTableViewCellIdentifier)
        if let _ = cell {
            
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: fileTableViewCellIdentifier)
        }
        
        cell?.textLabel?.text = filtedFileNames[indexPath.row] + (Utility.hasNoteImage(for: filtedFileNames[indexPath.row]) ? hasNoteImageIcon : "")
        cell?.detailTextLabel?.text = getTagListString(for: filtedFileNames[indexPath.row])
        
        return cell!
    }
}

// MARK: - UIPickerViewDelegate
extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return allTagsForSelector[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tagSelector.text = allTagsForSelector[row]
        tagSelector.resignFirstResponder()
        fileTableView.reloadData()
    }
}

// MARK: - UIPickerViewDataSource
extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        allTagsForSelector.count
    }
}

// MARK: - UISearchBarDelegate
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fileTableView.reloadData()
    }
}

// MARK: - EditTagViewControllerDelegate
extension ViewController: EditTagViewControllerDelegate {
    func confirmEditingTags(with allTags: [String], selectedTags: [String], fileName: String) {
        func buildTagsInfoParam() -> String? {
            var tagsInfoDic = [String: [String]]()
            
            if allTags.count > 0 {
                tagsInfoDic[allTagsKey] = allTags
            }
            if selectedTags.count > 0 {
                tagsInfoDic[fileName] = selectedTags
            }
            
            if let tagsInfoData = try? JSONSerialization.data(withJSONObject: tagsInfoDic, options: .prettyPrinted) {
                return String(data: tagsInfoData, encoding: .utf8)
            }
            
            return nil
        }
        
        self.allTags = allTags
        self.allTagsForSelector = allTags
        self.allTagsForSelector.insert(allTagConstant, at: 0)
        self.allFileTags[fileName] = selectedTags
        self.fileTableView.reloadData()
        
        if let tagsInfo = buildTagsInfoParam() {
            Utility.sendRequest(apiPath: "allTags", httpMethod: "PUT", params: ["tagsInfo": tagsInfo])
            
            // 更新缓存
            CacheManager.shared.cacheAllTags(allTags)
            CacheManager.shared.cacheTagsForMusic(musicName: fileName, tags: selectedTags)
            
            // 由于标签已变更，需要重置缓存状态
            clearLocalCacheStatus()
        }
    }
}


