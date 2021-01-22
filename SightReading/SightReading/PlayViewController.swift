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
    @IBOutlet weak var tempoInput: UITextField!
    @IBOutlet weak var meterInput: UITextField!
    @IBOutlet weak var imageViewOuterContainer: UIView!
    @IBOutlet weak var imageViewInnerContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mask: Mask!
    
    private var barFrames = [Int: CGRect]()
    private let barCountBeforeBegin = 2
    
    private var stopMaskFlag = false
    
    private var firstMeterId: SystemSoundID = 1000;
    private var nonFirstMeterId: SystemSoundID = 1000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSoundIDs()
        loadJsonFile()
        loadSheetImage()
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
           let jsonObject = NSKeyedUnarchiver.unarchiveObject(with: jsonData),
           let barFrames = jsonObject as? [Int: CGRect] {
            self.barFrames =  barFrames
            return
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
                            let barIndex = meterIndex/meterPerBar + 1
                            let meterIndexInBar = meterIndex % meterPerBar + 1
                            if meterIndexInBar == 1 { // first meter in a bar
                                print("meter \(meterIndexInBar) in before-beginning bar \(barIndex)")
                            } else {
                                print("meter \(meterIndexInBar) in before-beginning bar \(barIndex)")
                            }
                        } else { // mask is moviving
                            let realMeterIndex = meterIndex - self.barCountBeforeBegin * meterPerBar
                            let realBarIndex = realMeterIndex / meterPerBar + 1
                            let meterIndexInBar = meterIndex % meterPerBar + 1
                            if meterIndexInBar == 1 { // first meter in a bar
                                print("meter 1 in bar \(realBarIndex)")
                                
                                if let barFrame = self.barFrames[realBarIndex] {
                                    self.mask.frame = Utility.getAbsoluteRect(with: barFrame, in: self.imageView.frame.size)
                                }
                            } else {
                                print("meter \(meterIndexInBar) in bar \(realBarIndex)")
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
