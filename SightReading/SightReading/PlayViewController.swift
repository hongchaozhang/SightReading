//
//  PlayViewController.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import Foundation
import UIKit
import AVFoundation

let meterValues: [String] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]

let tempoDisplaySymbols = ["Larghissimo",
                           "Grave",
                           "Lento",
                           "Largo",
                           "Larghetto",
                           "Adagio",
                           "Adagietto",
                           "Andante",
                           "Andante",
                           "Andantino",
                           "Marcia moderato",
                           "Moderato",
                           "Allegretto",
                           "Allegro",
                           "Vivace",
                           "Vivacissimo",
                           "Allegrissimo",
                           "Presto",
                           "Prestissimo"]

let tempoFullSymbols = ["Larghissimo － 极端地缓慢（10-19bpm）",
                    "Grave － 沉重的、严肃的（20-40bpm）",
                    "Lento － 缓板（41-45 bpm）",
                    "Largo － 最缓板（现代）或广板（46-50bpm）",
                    "Larghetto － 甚缓板（51-55bpm）",
                    "Adagio － 柔板 / 慢板（56-65 bpm）",
                    "Adagietto － 颇慢（66-69bpm）",
                    "Andante moderato -中慢板（70-72bpm）",
                    "Andante － 行板（73 - 77 bpm）",
                    "Andantino － 稍快的行板（78-83bpm）",
                    "Marcia moderato - 行进中（84-85bpm）",
                    "Moderato － 中板（86 - 97 bpm）",
                    "Allegretto － 稍快板（98-109bpm）（比 Allegro 较少见）",
                    "Allegro (Moderato) － 快板（110-132bpm）",
                    "Vivace － 活泼的快板（133-140 bpm）",
                    "Vivacissimo -非常快的快板(141-150bpm)",
                    "Allegrissimo -极快的快板(151-167bpm)",
                    "Presto － 急板（168 -177bpm）",
                    "Prestissimo － 最急板（178 - 500 bpm）"]
let tempoValues: [String: [String: Int]] = ["Larghissimo － 极端地缓慢（10-19bpm）": ["min": 10, "max":19, "value": 15],
                                            "Grave － 沉重的、严肃的（20-40bpm）": ["min": 20, "max":40, "value": 30],
                                            "Lento － 缓板（41-45 bpm）": ["min": 41, "max":45, "value": 43],
                                            "Largo － 最缓板（现代）或广板（46-50bpm）": ["min": 46, "max":50, "value": 48],
                                            "Larghetto － 甚缓板（51-55bpm）": ["min": 51, "max":55, "value": 53],
                                            "Adagio － 柔板 / 慢板（56-65 bpm）": ["min": 56, "max":65, "value": 60],
                                            "Adagietto － 颇慢（66-69bpm）": ["min": 66, "max":69, "value": 68],
                                            "Andante moderato -中慢板（70-72bpm）": ["min": 70, "max":72, "value": 71],
                                            "Andante － 行板（73 - 77 bpm）": ["min": 73, "max":77, "value": 75],
                                            "Andantino － 稍快的行板（78-83bpm）": ["min": 78, "max":83, "value": 80],
                                            "Marcia moderato - 行进中（84-85bpm）": ["min": 84, "max":85, "value": 85],
                                            "Moderato － 中板（86 - 97 bpm）": ["min": 86, "max":97, "value": 90],
                                            "Allegretto － 稍快板（98-109bpm）（比 Allegro 较少见）": ["min": 98, "max":109, "value": 105],
                                            "Allegro (Moderato) － 快板（110-132bpm）": ["min": 110, "max":132, "value": 120],
                                            "Vivace － 活泼的快板（133-140 bpm）": ["min": 133, "max":140, "value": 135],
                                            "Vivacissimo -非常快的快板(141-150bpm)": ["min": 141, "max":150, "value": 145],
                                            "Allegrissimo -极快的快板(151-167bpm)": ["min": 151, "max":167, "value": 160],
                                            "Presto － 急板（168 -177bpm）": ["min": 168, "max":177, "value": 170],
                                            "Prestissimo － 最急板（178 - 500 bpm）": ["min": 178, "max":500, "value": 200]]

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
    private let barCountBeforeBegin = 2
    
    private var stopMaskFlag = false
    
    private var firstMeterId: SystemSoundID = 1000;
    private var nonFirstMeterId: SystemSoundID = 1000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupControls()
        createSoundIDs()
        loadJsonFile()
        loadSheetImage()
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
    
    private func restoreSettings() {
        if let tempo = sheetBasicInfo[tempoKey],
           let _ = Int(tempo) {
            tempoInput.text = tempo
        }
        if let meter = sheetBasicInfo[meterKey],
           let _ = Int(meter) {
            meterInput.text = meter
        }
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
    
    private func loadSheetImage() {
        if let rootPath = Utility.getRootPath(),
           let imageName = navigationItem.title,
           let image2 = UIImage(contentsOfFile: "\(rootPath)/\(imageName).png") {
            imageView.image = image2
            layoutImageView()
        }
    }
    
    @IBAction func start(_ sender: Any) {
        startButton.isHidden = true
        stopButton.isHidden = false
        stopMaskFlag = false
        
        animateMask()
    }
    
    @IBAction func stop(_ sender: Any) {
        stopButton.isHidden = true
        startButton.isHidden = false
        stopMaskFlag = true
        mask.frame = .zero
    }
    
    private func animateMask() {
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
                                    self.mask.frame = Utility.getAbsoluteRect(with: barFrame, in: self.imageView.frame.size)
                                }
                            } else {
//                                print("meter \(meterIndexInBar) in bar \(realBarIndex)")
                            }
                        }
                        
                        meterIndex += 1
                        animateMask()
                        
                    } else {
                        self.stop(UIButton())
                    }
                })
            }
            
            animateMask()

        }
    }
    
    func layoutImageView() {
        guard let imageSize = imageView.image?.size else {
            return
        }

        let innerContainerFrame = Utility.fit(size: imageSize, into: imageViewOuterContainer.frame.size)
        imageViewInnerContainer.frame = innerContainerFrame
        imageView.frame = imageViewInnerContainer.bounds
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImageView()
        mask.frame = .zero
    }
}

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

extension PlayViewController: UITextFieldDelegate {
    
    func getTempoSymbol(from tempoString: String?) -> String? {
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
