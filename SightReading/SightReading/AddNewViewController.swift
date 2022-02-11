//
//  AddNewViewController.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import Foundation
import UIKit
import Photos

class AddNewViewController: UIViewController {
    private let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    
    @IBOutlet weak var sheetNameInput: UITextField!
    @IBOutlet weak var barIndexInput: UITextField!
    
    @IBOutlet weak var imageViewOuterContainer: UIView!
    @IBOutlet weak var imageViewInnerContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mask: Mask!
    
    private var barFrames = [Int: CGRect]()
    private var startPoint = CGPoint.zero
    private var endPoint = CGPoint.zero
    
    // MARK: - override super functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar()
        addPanGesture()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            startPoint = touch.location(in: imageView) // pan gesture start point a an offset
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImageView()
        mask.frame = .zero
    }
    
    // MARK: - private functions
    private func layoutImageView() {
        guard let imageSize = imageView.image?.size else {
            return
        }

        let innerContainerFrame = Utility.fit(size: imageSize, into: imageViewOuterContainer.frame.size)
        imageViewInnerContainer.frame = innerContainerFrame
        imageView.frame = imageViewInnerContainer.bounds
    }
    
    private func addMask() {
        view.addSubview(mask)
    }
    
    private func setNavigationBar() {
        navigationItem.title = "Add New"
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(addNewDone))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panHandler(_:)))
        view.addGestureRecognizer(pan)
    }
    
    @objc func panHandler(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            mask.frame = CGRect.zero
        } else if gesture.state == .changed {
            let currentPoint = gesture.location(in: imageView)
            let rect = Utility.getRect(with: startPoint, and: currentPoint)
            mask.frame = rect
        } else if gesture.state == .ended {
            endPoint = gesture.location(in: imageView)
            let rect = Utility.getRect(with: startPoint, and: endPoint)
            if let barIndexString = barIndexInput.text, let barIndex = Int(barIndexString), barIndex > 0 {
                barFrames[barIndex] = Utility.getRelativeRect(with: rect, in: imageView.frame.size)
                barIndexInput.text = String(barIndex + 1)
            }
        } else if gesture.state == .cancelled || gesture.state == .failed {
            
        }
    }
    
    // MARK: - handlers
    private func getFileName() -> String? {
        if let sheetName = sheetNameInput.text, sheetName != "" {
            return sheetName
        }
        
        return nil
    }
    
    private func saveFiles() {
        func saveImageFile() {
            if let imageName = getFileName() {
                if let image = imageView.image, let imageData = image.pngData() {
                    Utility.uploadFileToServer(fileData: imageData, fileName: imageName, musicFileType: .sheet)
                }
            }
        }
        
        func saveJsonFile() {
            if let jsonFileName = getFileName() {
                let newBarFrames = Utility.convertBarFramesToString(barFrames)
                let jsonDic: [String: Any] = [basicInfoKey: [String: String](), barFramesKey: newBarFrames]

                if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted) {
                    Utility.uploadFileToServer(fileData: jsonData, fileName: jsonFileName, musicFileType: .json)
                }
            }
        }
        
        saveJsonFile()
        saveImageFile()
    }
    
    @objc func addNewDone() {
        if let rootPath = Utility.getRootPath() {
            if let fileName = getFileName() {
                let jsonFilePath = "\(rootPath)/\(fileName).json"
                let imageFilePath = "\(rootPath)/\(fileName).png"
                
                if FileManager.default.fileExists(atPath: jsonFilePath) || FileManager.default.fileExists(atPath: imageFilePath) {
                    let alert = UIAlertController(title: "Warning", message: "There is already files named \(fileName). Clike OK will override it.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self.saveFiles()
                        self.navigationController?.popViewController(animated: true)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    saveFiles()
                    navigationController?.popViewController(animated: true)
                }
            } else {
                let alert = UIAlertController(title: "Warning", message: "A name should be set before saving.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func minusBarIndex(_ sender: Any) {
        if let barIndexString = barIndexInput.text, let barIndex = Int(barIndexString), barIndex > 1 {
            barIndexInput.text = String(barIndex - 1)
        }
    }
    @IBAction func addBarIndex(_ sender: Any) {
        if let barIndexString = barIndexInput.text, let barIndex = Int(barIndexString) {
            barIndexInput.text = String(barIndex + 1)
        }
    }
    @IBAction func openSheetImage(_ sender: Any) {
        if let photoCollectionVC = storyboard?.instantiateViewController(identifier: "PhotoCollection") as? PhotoCollectionViewController {
            photoCollectionVC.delegate = self
            navigationController?.pushViewController(photoCollectionVC, animated: true)
        }
    }
}

// MARK: - PhotoCollectionViewControllerDelegate
extension AddNewViewController: PhotoCollectionViewControllerDelegate {
    func set(image: UIImage, and name: String?) {
        imageView.image = image
        sheetNameInput.text = name ?? ""
        layoutImageView()
        barFrames = [Int: CGRect]()
        mask.frame = CGRect.zero
    }
}
