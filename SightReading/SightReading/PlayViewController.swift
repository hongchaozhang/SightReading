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
    @IBOutlet weak var tempoSelector: UITextField!
    private var tempoPickerView: UIPickerView!
    @IBOutlet weak var tempoInput: UITextField!
    private var meterPickerView: UIPickerView!
    @IBOutlet weak var meterInput: UITextField!
    @IBOutlet weak var imageViewOuterContainer: UIView!
    @IBOutlet weak var imageViewInnerContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mask: Mask!
    
    private var sheetBasicInfo = [String: String]()
    private var barFrames = [Int: CGRect]()
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
        createSoundIDs()
        loadJsonFile()
        loadCurrentSheetImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreSettings()
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
        guard let imageSize = imageView.image?.size else {
            return
        }

        let innerContainerFrame = Utility.fit(size: imageSize, into: imageViewOuterContainer.frame.size)
        imageViewInnerContainer.frame = innerContainerFrame
        imageView.frame = imageViewInnerContainer.bounds
    }
    
    // MARK: -
    private func restoreSettings() {
        if let tempo = sheetBasicInfo[tempoKey],
           let tempoSymbol = getTempoSymbol(from: tempo) {
            tempoInput.text = tempo
            tempoSelector.text = tempoSymbol
            tempoPickerView.selectRow(tempoDisplaySymbols.firstIndex(of: tempoSymbol)!, inComponent: 0, animated: true)
        }
        if let meter = sheetBasicInfo[meterKey],
           let _ = Int(meter) {
            meterInput.text = meter
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
        
        sheetBasicInfo[tempoKey] = tempoString
        sheetBasicInfo[meterKey] = meterString
        
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
            tempoPickerView.selectRow(11, inComponent: 0, animated: true)
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
        meterPickerView.selectRow(2, inComponent: 0, animated: true)
        
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
           let image2 = UIImage(contentsOfFile: "\(rootPath)/\(imageName).png") {
            imageView.image = image2
            layoutImageView()
        }
    }
    
    private func loadCurrentSheetImage() {
        if let imageName = navigationItem.title {
            loadSheetImage(with: imageName)
        }
    }
    
    private func loadNextSheetImage() {
        if let nextPageImageName = getNewTitle() {
            loadSheetImage(with: nextPageImageName)
        }
    }
    // MARK: - support multiple pages
    
    // MARK: - support full screen image view
    
    // MARK: - animations
    @IBAction func start(_ sender: Any) {
        startButton.isHidden = true
        stopButton.isHidden = false
        stopMaskFlag = false
        
        startAnimateMask()
    }
    
    @IBAction func stop(_ sender: Any) {
        stopButton.isHidden = true
        startButton.isHidden = false
        stopMaskFlag = true
        mask.frame = .zero
    }
    
    // test1 -> test2
    private func getNewTitle() -> String? {
        if let currentTitle = navigationItem.title,
           let pageIndexCharactor = currentTitle.last,
           let pageIndex = Int(String(pageIndexCharactor)) {
            let titlePrefixIndex = currentTitle.index(currentTitle.startIndex, offsetBy: currentTitle.count - 1)
            let titlePrefix = currentTitle.substring(to: titlePrefixIndex)
            let newTitle = titlePrefix + String(pageIndex + 1)
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
        if let _ = getNewTitle() {
            return true
        }
        
        return false
    }
    
    private func startAnimateMask() {
        if let tempoString = tempoInput.text,
           let tempo = Double(tempoString),
           let meterString = meterInput.text,
           let meterPerBar = Int(meterString) {
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
                            if meterIndexInBar == 1 { // first meter in a bar
                                if let barFrame = self.barFrames[realBarIndex] {
                                    if realBarIndex == totalBarCount && self.hasNextPage() {
                                        // load the next page at the beginning of the last bar of the previous page so the the user has time to read the first bar of the new page
                                        self.mask.frame = .zero
                                        self.loadNextSheetImage()
                                    } else {
                                        self.mask.frame = Utility.getAbsoluteRect(with: barFrame, in: self.imageView.frame.size)
                                    }
                                    
                                }
                            } else {
//                                print("meter \(meterIndexInBar) in bar \(realBarIndex)")
                            }
                        }
                        
                        meterIndex += 1
                        if meterIndex == totalMeters,
                           let newTitle = self.getNewTitle() {
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
        } else {
            return meterValues[row]
        }
        
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
        } else {
            meterInput.text = meterValues[row]
            meterInput.resignFirstResponder()
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
        } else {
            return meterValues.count
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
