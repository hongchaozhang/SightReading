//
//  PlayViewController.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import Foundation
import UIKit
import AVFoundation

class PlayViewController: UIViewController {
    @IBOutlet weak var startStopPlayingButton: UIButton!
    @IBOutlet weak var showHideNoteButton: UIButton!
    
    @IBOutlet weak var controlsContainerStack: UIStackView!
    @IBOutlet weak var tempoSelector: UITextField!
    private var tempoPickerView: UIPickerView!
    @IBOutlet weak var tempoInput: UITextField!
    private var meterPickerView: UIPickerView!
    @IBOutlet weak var meterInput: UITextField!
    private var maskOffsetPickerView: UIPickerView!
    private var maskOffsetValues = [String]() // mask offset value should be less than the meterInput value.
    @IBOutlet weak var maskOffsetInput: UITextField!
    @IBOutlet weak var imageViewOuterContainer: UIView!
    @IBOutlet weak var imageViewInnerContainer: UIView!
    @IBOutlet weak var sheetImageView: UIImageView!
    @IBOutlet weak var noteImageView: UIImageView!
    @IBOutlet weak var mask: Mask!
    private var isPlaying = false
    
    private var sheetBasicInfo = [String: String]()
    private var barFrames = [Int: CGRect]() // 1-based
    private var isFirstPage = true
    private var barCountBeforeBegin: Int {
        get {
            return isFirstPage ? 2 : 0
        }
    }
    
    private var stopMaskFlag = false
    
    private var firstMeterId: SystemSoundID = 1000;
    private var nonFirstMeterId: SystemSoundID = 1000
    
    @IBOutlet var currentPageLabel: UILabel!
    @IBOutlet var totalPageLabel: UILabel!
    private var currentPageIndex: Int = 0
    private var totalPageCount: Int = 1
//    private var notePageIndices = [Int]()
    private var isSinglePageMusic = true
    private var cachedResources = [Int: [String: Data]]()
    
    // MARK: - override super functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupControls()
        setupNavigationbar()
        createSoundIDs()
        loadMusicFileResources()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isPlaying = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaying()
        storeSettings()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImageView()
        mask.frame = .zero
    }
    
    // MARK: - take note
    private func setupNavigationbar() {
        let editBarItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
        navigationItem.rightBarButtonItem = editBarItem
    }
    
    @objc func editButtonTapped() {
        if let takeNoteVC = storyboard?.instantiateViewController(identifier: "note") as? TakeNoteViewController {
            takeNoteVC.sheetImage = sheetImageView.image
            takeNoteVC.noteImage = noteImageView.image
            takeNoteVC.delegate = self
            navigationController?.pushViewController(takeNoteVC, animated: true)
        }
    }
    
    @IBAction func showHideNote() {
        if noteImageView.isHidden {
            noteImageView.isHidden = false
            showHideNoteButton.setTitle("Hide Note", for: .normal)
        } else {
            noteImageView.isHidden = true
            showHideNoteButton.setTitle("Show Note", for: .normal)
        }
    }
    
    // MARK: - private functions
    private func getTempoSymbol(from tempoString: String?) -> String? {
        var tempoSymbol: String?
        if let tempoString = tempoString,
           let tempoValue = Int(tempoString) {
            for (tempoFullSymbol, tempoInfo) in tempoValues {
                if let minTempo = tempoInfo["min"],
                   let maxTempo = tempoInfo["max"],
                   tempoValue >= minTempo && tempoValue <= maxTempo,
                   let symbolIndex = tempoFullSymbols.firstIndex(of: tempoFullSymbol) {
                    tempoSymbol = tempoDisplaySymbols[symbolIndex]
                }
            }
        }
        
        return tempoSymbol
    }
    
    private func layoutImageView() {
        guard let imageSize = sheetImageView.image?.size else {
            return
        }

        let innerContainerFrame = Utility.fit(size: imageSize, into: imageViewOuterContainer.frame.size)
        if imageViewInnerContainer.frame != innerContainerFrame {
            imageViewInnerContainer.frame = innerContainerFrame
            sheetImageView.frame = imageViewInnerContainer.bounds
            if let _ = noteImageView.image {
                noteImageView.frame = imageViewInnerContainer.bounds
            }
            imageViewInnerContainer.alpha = 0
            UIView.animate(withDuration: 0.2) { // 0.2: can not be set too big, or when the page is automatically changed, there may be some delay to show the new page, and there is no time for the user to read the new music notes
                self.imageViewInnerContainer.alpha = 1.0
            }
        }
    }
    
    // MARK: -
    private func restoreSettings() {
        if let tempo = sheetBasicInfo[tempoKey],
           let tempoSymbol = getTempoSymbol(from: tempo) {
            tempoInput.text = tempo
            tempoSelector.text = tempoSymbol
            tempoPickerView.selectRow(tempoDisplaySymbols.firstIndex(of: tempoSymbol)!, inComponent: 0, animated: false)
        }
        if let meterString = sheetBasicInfo[meterKey],
           let meter = Int(meterString) {
            meterInput.text = meterString
            meterPickerView.selectRow(meterValues.firstIndex(of: meterString)!, inComponent: 0, animated: false)
            resetMaskOffsetValues(from: meter)
            maskOffsetPickerView.reloadAllComponents()
        }
        if let maskOffset = sheetBasicInfo[maskOffsetKey],
           let _ = Int(maskOffset) {
            maskOffsetInput.text = maskOffset
            maskOffsetPickerView.selectRow(maskOffsetValues.firstIndex(of: maskOffset)!, inComponent: 0, animated: false)
        }
        isFirstPage = true
    }
    
    private func storeSettings() {
        guard let tempoString = tempoInput.text,
              let _ = Int(tempoString) else {
            return
        }
        guard let meterString = meterInput.text,
              let _ = Int(meterString) else {
            return
        }
        guard let maskOffsetString = maskOffsetInput.text,
              let _ = Int(maskOffsetString) else {
            return
        }
        
        sheetBasicInfo[tempoKey] = tempoString
        sheetBasicInfo[meterKey] = meterString
        sheetBasicInfo[maskOffsetKey] = maskOffsetString
        let newBarFrames = Utility.convertBarFramesToString(barFrames)
        
        let jsonDic: [String: Any] = [basicInfoKey: sheetBasicInfo, barFramesKey: newBarFrames]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted),
           let musicName = navigationItem.title {
            let pageIndexString = isSinglePageMusic ? "" : "\(currentPageIndex+1)"
            let jsonFileName = "\(musicName)\(pageIndexString)"
            Utility.uploadFileToServer(fileData: jsonData, fileName: jsonFileName, musicFileType: .json)
        }
    }
    
    // MARK: - control setup
    private func setupControls() {
        setupMetricInput()
        setupTempoControls()
        setupMaskOffsetInput()
    }
    
    private func setupTempoControls() {
        func setupTempoSelector() {
            tempoPickerView = UIPickerView()
            tempoPickerView.delegate = self
            tempoPickerView.dataSource = self
            tempoSelector.inputView = tempoPickerView
            
            // setup default values
            tempoSelector.text = tempoDisplaySymbols[11] // Moderato
            tempoInput.text = "90"
            tempoPickerView.selectRow(11, inComponent: 0, animated: false)
        }
        
        func setupTempoInput() {
            tempoInput.delegate = self
        }
        
        setupTempoSelector()
        setupTempoInput()
    }
    
    private func setupMetricInput() {
        meterPickerView = UIPickerView()
        meterPickerView.delegate = self
        meterPickerView.dataSource = self
        meterInput.inputView = meterPickerView
        
        // setup default values
        meterInput.text = "4"
        meterPickerView.selectRow(2, inComponent: 0, animated: false)
        resetMaskOffsetValues(from: 4)
        
    }
    
    private func resetMaskOffsetValues(from max: Int) {
        if max > 0 {
            maskOffsetValues = [String]()
            for offsetValue in 0..<max {
                maskOffsetValues.append(String(offsetValue))
            }
        }
    }
    
    private func setupMaskOffsetInput() {
        maskOffsetPickerView = UIPickerView()
        maskOffsetPickerView.delegate = self
        maskOffsetPickerView.dataSource = self
        maskOffsetInput.inputView = maskOffsetPickerView
        
        maskOffsetInput.text = "0"
        maskOffsetPickerView.selectRow(0, inComponent: 0, animated: false)
    }
    
    // MARK: - load resources
    private func createSoundIDs() {
        if let audioUrl = Bundle.main.url(forResource: "FirstMeter", withExtension: "wav", subdirectory: "Resource.bundle")  {
            AudioServicesCreateSystemSoundID(audioUrl as CFURL, &firstMeterId)
        }
        if let audioUrl = Bundle.main.url(forResource: "NonFirstMeter", withExtension: "wav", subdirectory: "Resource.bundle") {
            AudioServicesCreateSystemSoundID(audioUrl as CFURL, &nonFirstMeterId)
        }
    }
    
    private func loadMusicFileResources() {
        func onSuccess(_ data: Data?) {
            do {
                let fileInfoDic = try JSONSerialization.jsonObject(with: data!) as! [String: Any]
                print(fileInfoDic)
                if let pageCount = fileInfoDic[pageCountKey] as? Int {
                    DispatchQueue.main.async {
                        self.totalPageCount = pageCount
                        self.totalPageLabel.text = String(pageCount)
                        if pageCount > 0 {
                            self.setCurrentPageIndex(0)
                        } else {
                            self.currentPageLabel.text = "-"
                        }
                    }
                    self.isSinglePageMusic = pageCount == 1
                }
//                if let notePageIndices = fileInfoDic[notePageIndicesKey] as? [Int] {
//                    self.notePageIndices = notePageIndices
//                }
                if let musicFileNames = fileInfoDic[musicFileNamesKey] as? [String] {
                    self.loadMusicFiles(musicFileNames)
                }
                
            } catch {
                print("error")
            }
        }
        
        Utility.sendRequest(apiPath: "musicFileInfo", params: ["musicName": navigationItem.title!], onSuccess: onSuccess(_:))
        
    }
    
    private func loadMusicFiles(_ musicFileNames: [String]) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "music file download", attributes: .concurrent)
        
        for fileName in musicFileNames {
            let noneUIPageIndex = Utility.getUIPageIndex(from: fileName) - 1
            
            queue.async(group: group) {
                group.enter()
                
                func onSuccess(_ data: Data?) {
                    if let data = data {
                        if self.cachedResources[noneUIPageIndex] == nil {
                            self.cachedResources[noneUIPageIndex] = [String: Data]()
                        }
                        self.cachedResources[noneUIPageIndex]![fileName] = data;
                    }
                    group.leave()
                }
                
                func onFailure(_ error: Error?) {
                    group.leave()
                }
                
                Utility.sendRequest(apiPath: "musicFile", params: ["musicFileName": fileName], onSuccess: onSuccess(_:), onFailure: onFailure(_:))

            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("all music files are downloaded.")
            self.loadCurrentJsonFile()
            self.loadCurrentSheetAndNoteImages()
        }
    }
    
    private func loadSheetAndNoteImages(with pageIndex: Int) {
        if let onePageResources = cachedResources[pageIndex],
           let musicName = navigationItem.title {
            let pageIndexString = isSinglePageMusic ? "" : "\(pageIndex+1)"
            let sheetFileName = "\(musicName)\(pageIndexString).png"
            let noteFileName = "\(musicName)\(pageIndexString)\(noteImageSubfix).png"
            if let sheetImageData = onePageResources[sheetFileName],
               let sheetImage = UIImage.init(data: sheetImageData) {
                sheetImageView.image = sheetImage
            } else {
                sheetImageView.image = nil
            }
            if let noteImageData = onePageResources[noteFileName],
               let noteImage = UIImage.init(data: noteImageData) {
                noteImageView.image = noteImage
            } else {
                noteImageView.image = nil
            }
            layoutImageView()
        }
    }
    
    private func loadCurrentSheetAndNoteImages() {
        loadSheetAndNoteImages(with: currentPageIndex)
    }
    
    private func loadNextSheetAndNoteImages() {
        loadSheetAndNoteImages(with: currentPageIndex + 1)
    }
    
    private func loadPriviousSheetAndNoteImages() {
        loadSheetAndNoteImages(with: currentPageIndex - 1)
    }
    
    private func loadJsonFile(with pageIndex: Int) {
        if let onePageResources = cachedResources[pageIndex],
           let musicName = navigationItem.title {
            let pageIndexString = isSinglePageMusic ? "" : "\(pageIndex+1)"
            let jsonFileName = "\(musicName)\(pageIndexString).json"
            if let jsonData = onePageResources[jsonFileName] {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
                    if let sheetBasicInfo = json[basicInfoKey] as? [String: String] {
                        self.sheetBasicInfo = sheetBasicInfo
                        DispatchQueue.main.async {
                            self.restoreSettings()
                        }
                    }
                    if let barFrames = json[barFramesKey] as? [String: [String]] {
                        var newBarFrames = [Int: CGRect]()
                        for (key, value) in barFrames {
                            if let newKey = Int(key), value.count == 4 {
                                if let x = Double(value[0]),
                                   let y = Double(value[1]),
                                   let w = Double(value[2]),
                                   let h = Double(value[3]) {
                                    let rect = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))
                                    newBarFrames[newKey] = rect
                                }
                            }
                        }
                        self.barFrames =  newBarFrames
                    }
                } catch {
                    print("Error")
                }
            }
        }
    }
    private func loadCurrentJsonFile() {
        loadJsonFile(with: currentPageIndex)
    }
    
    // MARK: - support multiple pages
    
    private func setCurrentPageIndex(_ index: Int) {
        if index < 0 || index >= totalPageCount {
            return
        }
        
        currentPageIndex = index
        currentPageLabel.text = String(index + 1)
    }
    
    private func hasNextPage() -> Bool {
        return currentPageIndex + 1 < totalPageCount
    }
    
    private func hasPreviousPage() -> Bool {
        return currentPageIndex > 0
    }
    
    @IBAction func imageRightSwiped(_ sender: UISwipeGestureRecognizer) {
        // change to the privouse page
        if !isPlaying && hasPreviousPage() {
            setCurrentPageIndex(currentPageIndex - 1)
            loadCurrentJsonFile()
            loadCurrentSheetAndNoteImages()
        }
    }
    
    @IBAction func imageLeftSwiped(_ sender: UISwipeGestureRecognizer) {
        // change to the next page
        if !isPlaying && hasNextPage() {
            setCurrentPageIndex(currentPageIndex + 1)
            loadCurrentJsonFile()
            loadCurrentSheetAndNoteImages()
        }
    }
    
    // MARK: - support full screen image view
    @IBAction func imageDoubleTapped(_ sender: UITapGestureRecognizer) {
        if let isHidden = navigationController?.navigationBar.isHidden {
            navigationController?.setNavigationBarHidden(!isHidden, animated: true)
        }
    }
    
    // MARK: - animations
    @IBAction func startStopPlaying(_ sender: Any) {
        if !isPlaying {
            startPlaying()
        } else {
            stopPlaying()
        }
    }
    
    private func startPlaying() {
        startStopPlayingButton.setTitle("Stop", for: .normal)
        stopMaskFlag = false
        isPlaying = true
        startAnimateMask()
    }
    
    private func stopPlaying() {
        startStopPlayingButton.setTitle("Start", for: .normal)
        stopMaskFlag = true
        isPlaying = false
        mask.frame = .zero
    }
    
    private func startAnimateMask() {
        if let tempoString = tempoInput.text,
           let tempo = Double(tempoString),
           let meterString = meterInput.text,
           let meterPerBar = Int(meterString),
           let maskOffsetString = maskOffsetInput.text,
           let maskOffset = Int(maskOffsetString) {
            mask.frame = CGRect.zero
            var meterIndex = 0
            let totalBarCount = barFrames.count
            let timePerMeter = 60 / tempo // 每一拍的时间
            let totalMeters = meterPerBar * (totalBarCount + barCountBeforeBegin)
            
            func animateMask() {
                DispatchQueue.main.asyncAfter(deadline: .now() + timePerMeter, execute: {
                    if meterIndex < totalMeters && self.stopMaskFlag == false {
                        
                        if meterIndex % meterPerBar + 1 == 1 { // first meter in a bar
                            AudioServicesPlaySystemSound(self.firstMeterId)
                        } else {
                            AudioServicesPlaySystemSound(self.nonFirstMeterId)
                        }
                        
                        if meterIndex < self.barCountBeforeBegin * meterPerBar { // before beginning
//                            let barIndex = meterIndex/meterPerBar + 1
//                            let meterIndexInBar = meterIndex % meterPerBar + 1
//                            if meterIndexInBar == 1 { // first meter in a bar
//                                print("meter \(meterIndexInBar) in before-beginning bar \(barIndex)")
//                            } else {
//                                print("meter \(meterIndexInBar) in before-beginning bar \(barIndex)")
//                            }
                        } else { // mask is moviving
                            let realMeterIndex = meterIndex - self.barCountBeforeBegin * meterPerBar
                            let realBarIndex = realMeterIndex / meterPerBar + 1
                            let meterIndexInBar = meterIndex % meterPerBar + 1
                            if meterIndexInBar == 1 + maskOffset { // first meter in a bar (maskOffset = 0)
                                if let barFrame = self.barFrames[realBarIndex] {
                                    if realBarIndex == totalBarCount && self.hasNextPage() {
                                        // load the next page at the beginning of the last bar of the previous page so the the user has time to read the first bar of the new page
                                        self.mask.frame = .zero
                                        self.loadNextSheetAndNoteImages()
                                    } else {
                                        self.mask.frame = Utility.getAbsoluteRect(with: barFrame, in: self.sheetImageView.frame.size)
                                    }
                                    
                                }
                            } else {
//                                print("meter \(meterIndexInBar) in bar \(realBarIndex)")
                            }
                        }
                        
                        meterIndex += 1
                        if meterIndex == totalMeters && self.hasNextPage() {
                            self.isFirstPage = false
                            self.setCurrentPageIndex(self.currentPageIndex + 1)
                            self.loadCurrentJsonFile()
                            // load the next page at the beginning of the last bar of the previous page, not the end of the last bar
                            // self.loadCurrentSheetAndNoteImages()
                            self.startAnimateMask()
                        } else {
                            animateMask()
                        }
                    } else {
                        self.stopPlaying()
                    }
                })
            }
            
            animateMask()

        }
    }
}

// MARK: - UIPickerViewDelegate
extension PlayViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == tempoPickerView {
            return tempoFullSymbols[row]
        } else if pickerView == meterPickerView {
            return meterValues[row]
        } else if pickerView == maskOffsetPickerView {
            return maskOffsetValues[row]
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == tempoPickerView {
            let tempoSymbol = tempoFullSymbols[row]
            if let tempoInfo = tempoValues[tempoSymbol],
               let tempoValue = tempoInfo["value"] {
                tempoInput.text = String(tempoValue)
            }
            tempoSelector.text = tempoDisplaySymbols[row]
            tempoSelector.resignFirstResponder()
        } else if pickerView == meterPickerView {
            meterInput.text = meterValues[row]
            if let meter = Int(meterValues[row]),
               let maskOffsetString = maskOffsetInput.text,
               let maskOffset = Int(maskOffsetString) {
                resetMaskOffsetValues(from: meter)
                maskOffsetPickerView.reloadAllComponents()
                if maskOffset >= meter {
                    maskOffsetInput.text = String(meter - 1)
                }
            }
            meterInput.resignFirstResponder()
        } else if pickerView == maskOffsetPickerView {
            maskOffsetInput.text = maskOffsetValues[row]
            maskOffsetInput.resignFirstResponder()
        }
    }
}

// MARK: - UIPickerViewDataSource
extension PlayViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == tempoPickerView {
            return tempoFullSymbols.count
        } else if pickerView == meterPickerView {
            return meterValues.count
        } else {
            return maskOffsetValues.count
        }
        
    }
}

// MARK: - UITextFieldDelegate
extension PlayViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let tempoSymbol = getTempoSymbol(from: textField.text) {
            tempoSelector.text = tempoSymbol
            tempoPickerView.selectRow(tempoDisplaySymbols.firstIndex(of: tempoSymbol)!, inComponent: 0, animated: true)
        } else {
            textField.text = "90"
        }
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let tempoSymbol = getTempoSymbol(from: textField.text) {
            tempoSelector.text = tempoSymbol
            tempoPickerView.selectRow(tempoDisplaySymbols.firstIndex(of: tempoSymbol)!, inComponent: 0, animated: true)
        }
    }
}

// MARK: - TakeNoteViewControllerDelegate
extension PlayViewController: TakeNoteViewControllerDelegate {
    func saveNote(with image: UIImage?) {
        if let image = image {
            noteImageView.frame = imageViewInnerContainer.bounds
            noteImageView.image = image
            if let musicName = navigationItem.title,
               let imageData = image.pngData() {
                let pageIndexString = isSinglePageMusic ? "" : "\(currentPageIndex+1)"
                let noteFileName = "\(musicName)\(pageIndexString)\(noteImageSubfix)"
                Utility.uploadFileToServer(fileData: imageData, fileName: noteFileName, musicFileType: .note)
            }
        }
    }
}
