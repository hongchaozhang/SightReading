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
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
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
    
    // MARK: - override super functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupControls()
        setupNavigationbar()
        createSoundIDs()
        loadJsonFile()
        loadCurrentSheetImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreSettings()
        isPlaying = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop(UIButton())
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
        
        if let rootPath = Utility.getRootPath(),
           let jsonFileName = navigationItem.title {
            let jsonPath = "\(rootPath)/\(jsonFileName).json"
            let jsonDic: [String: Any] = [basicInfoKey: sheetBasicInfo, barFramesKey: barFrames]
            if let jsonData = try? NSKeyedArchiver.archivedData(withRootObject: jsonDic, requiringSecureCoding: false) {
                FileManager.default.createFile(atPath: jsonPath, contents: jsonData, attributes: nil)
            }
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
    
    private func loadJsonFile() {
        if let rootPath = Utility.getRootPath(),
           let jsonName = navigationItem.title,
           let jsonData = FileManager.default.contents(atPath: "\(rootPath)/\(jsonName).json"),
           let jsonObjectAny = NSKeyedUnarchiver.unarchiveObject(with: jsonData),
           let jsonObject = jsonObjectAny as? [String: Any] {
            if let sheetBasicInfo = jsonObject[basicInfoKey] as? [String: String] {
                self.sheetBasicInfo = sheetBasicInfo
            }
            if let barFrames = jsonObject[barFramesKey] as? [Int: CGRect] {
                self.barFrames =  barFrames
            }
        }
    }
    
    private func loadSheetImage(with imageName: String) {
        if let rootPath = Utility.getRootPath(),
           let sheetImage = UIImage(contentsOfFile: "\(rootPath)/\(imageName).png") {
            sheetImageView.image = sheetImage
            if let noteImage = UIImage(contentsOfFile: "\(rootPath)/\(imageName)\(noteImageSubfix).png") {
                noteImageView.image = noteImage
            }
            layoutImageView()
        }
    }
    
    private func loadCurrentSheetImage() {
        if let imageName = navigationItem.title {
            loadSheetImage(with: imageName)
        }
    }
    
    private func loadNextSheetImage() {
        if let nextPageImageName = getNewTitle(isNext: true) {
            loadSheetImage(with: nextPageImageName)
        }
    }
    
    private func loadPriviousSheetImage() {
        if let nextPageImageName = getNewTitle(isNext: false) {
            loadSheetImage(with: nextPageImageName)
        }
    }
    // MARK: - support multiple pages
    // test1 -> test2
    private func getNewTitle(isNext: Bool) -> String? {
        if let currentTitle = navigationItem.title,
           let pageIndexCharactor = currentTitle.last,
           let pageIndex = Int(String(pageIndexCharactor)) {
            let titlePrefixIndex = currentTitle.index(currentTitle.startIndex, offsetBy: currentTitle.count - 1)
            let titlePrefix = currentTitle.substring(to: titlePrefixIndex)
            let newTitle = titlePrefix + String(isNext ? (pageIndex+1) : (pageIndex-1))
            if let rootPath = Utility.getRootPath() {
                let newPath = "\(rootPath)/\(newTitle).png"
                if FileManager.default.fileExists(atPath: newPath) {
                    return newTitle
                }
            }
        }
        return nil
    }
    
    private func hasNextPage() -> Bool {
        if let _ = getNewTitle(isNext: true) {
            return true
        }
        return false
    }
    
    private func hasPreviousPage() -> Bool {
        if let _ = getNewTitle(isNext: false) {
            return true
        }
        return false
    }
    
    @IBAction func imageRightSwiped(_ sender: UISwipeGestureRecognizer) {
        // change to the privouse page
        if !isPlaying, let newTitle = getNewTitle(isNext: false) {
            navigationItem.title = newTitle
            loadJsonFile()
            loadCurrentSheetImage()
        }
    }
    
    @IBAction func imageLeftSwiped(_ sender: UISwipeGestureRecognizer) {
        // change to the next page
        if !isPlaying, let newTitle = getNewTitle(isNext: true) {
            navigationItem.title = newTitle
            loadJsonFile()
            loadCurrentSheetImage()
        }
    }
    
    // MARK: - support full screen image view
    @IBAction func imageDoubleTapped(_ sender: UITapGestureRecognizer) {
        if let isHidden = navigationController?.navigationBar.isHidden {
            navigationController?.setNavigationBarHidden(!isHidden, animated: true)
        }
    }
    
    // MARK: - animations
    @IBAction func start(_ sender: Any) {
        startButton.isHidden = true
        stopButton.isHidden = false
        stopMaskFlag = false
        isPlaying = true
        
        startAnimateMask()
    }
    
    @IBAction func stop(_ sender: Any) {
        stopButton.isHidden = true
        startButton.isHidden = false
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
                                        self.loadNextSheetImage()
                                    } else {
                                        self.mask.frame = Utility.getAbsoluteRect(with: barFrame, in: self.sheetImageView.frame.size)
                                    }
                                    
                                }
                            } else {
//                                print("meter \(meterIndexInBar) in bar \(realBarIndex)")
                            }
                        }
                        
                        meterIndex += 1
                        if meterIndex == totalMeters,
                           let newTitle = self.getNewTitle(isNext: true) {
                            self.isFirstPage = false
                            self.navigationItem.title = newTitle
                            self.loadJsonFile()
                            // load the next page at the beginning of the last bar of the previous page, not the end of the last bar
                            // self.loadSheetImage()
                            self.startAnimateMask()
                        } else {
                            animateMask()
                        }
                    } else {
                        self.stop(UIButton())
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
            if let rootPath = Utility.getRootPath(),
               let fileName = navigationItem.title,
               let imageData = image.pngData() {
                let fullFilePath = "\(rootPath)/\(fileName)\(noteImageSubfix).png"
                FileManager.default.createFile(atPath: fullFilePath, contents: imageData, attributes: nil)
            }
        }
    }
}
