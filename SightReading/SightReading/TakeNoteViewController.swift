//
//  TakeNoteViewController.swift
//  SightReading
//
//  Created by Zhang, Hongchao on 2021/2/4.
//

import Foundation
import UIKit

protocol TakeNoteViewControllerDelegate: class {
    func saveNote(with image: UIImage?)
}

class TakeNoteViewController: UIViewController {
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var brushColorButton: BrushColorButton!
    @IBOutlet weak var brushWidthButton: BrushWidthButton!
    @IBOutlet weak var pencilButton: UIButton!
    @IBOutlet weak var eraserButton: UIButton!
    @IBOutlet weak var brushWidthSlider: UISlider!
    @IBOutlet weak var brushWidthSliderValueLabel: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var imageOuterContainer: UIView!
    @IBOutlet weak var imageInnerContainer: UIView!
    @IBOutlet weak var sketchView: ATSketchView!
    @IBOutlet weak var sheetImageView: UIImageView!
    @IBOutlet weak var noteImageView: UIImageView!
    var sheetImage: UIImage?
    var noteImage: UIImage?
    
    weak var delegate: TakeNoteViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSketchView()
        configureImageView()
        configureControls()
        configureSaveBarItem()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let imageSize = sheetImage?.size else {
            return
        }

        let innerContainerFrame = Utility.fit(size: imageSize, into: imageOuterContainer.frame.size)
        imageInnerContainer.frame = innerContainerFrame
        sketchView.frame = imageInnerContainer.bounds
        sheetImageView.frame = imageInnerContainer.bounds
        if let _ = noteImageView.image {
            noteImageView.frame = imageInnerContainer.bounds
        }
    }
    
    private func configureImageView() {
        sheetImageView.image = sheetImage
        noteImageView.image = noteImage
    }
    
    private func configureSketchView() {
        sketchView.backgroundColor = .clear
        sketchView.delegate = self
        sketchView.currentLineWidth = CGFloat(2.0)
        sketchView.currentTool = .pencil
        sketchView.currentColor = .systemBlue
//        if let sheetImage = sheetImage {
//            sketchView.addImageLayer(sheetImage, rect: sketchView.bounds, lineWidth: 0, color: .clear)
//        }
//        if let noteImage = noteImage {
//            sketchView.addImageLayer(noteImage, rect: sketchView.bounds, lineWidth: 0, color: .clear)
//        }
    }
    
    private func configureControls() {
        pencilButton.tintColor = .systemBlue
        eraserButton.tintColor = .lightGray
        brushColorButton.selectedColor = sketchView.currentColor
        brushWidthButton.selectedWidth = sketchView.currentLineWidth
        brushWidthSlider.value = Float(sketchView.currentLineWidth)
        brushWidthSlider.isHidden = true
        brushWidthSliderValueLabel.isHidden = true
        undoButton.isEnabled = sketchView.canUndo
        redoButton.isEnabled = sketchView.canRedo
        clearButton.isEnabled = sketchView.hasContent
    }
    
    private func configureSaveBarItem() {
        let saveBarItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
        navigationItem.rightBarButtonItem = saveBarItem
    }
    
    // MARK: - control callbacks
    @objc func saveButtonTapped() {
        if sketchView.hasContent {
            sheetImageView.removeFromSuperview()
            delegate?.saveNote(with: sketchView.produceImage(with: true))
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func undoButtonTapped() {
        sketchView.undo()
    }
    
    @IBAction func redoButtonTapped() {
        sketchView.redo()
    }
    
    @IBAction func brushColorButtonTapped() {
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.selectedColor = brushColorButton.selectedColor
        colorPickerVC.delegate = self
        present(colorPickerVC, animated: true, completion: nil)
    }
    
    @IBAction func brushWidthButtonTapped() {
        brushWidthSlider.isHidden = !brushWidthSlider.isHidden
        brushWidthSliderValueLabel.isHidden = brushWidthSlider.isHidden
    }
    
    @IBAction func pencilButtonTapped() {
        sketchView.currentTool = .pencil
        pencilButton.tintColor = .systemBlue
        eraserButton.tintColor = .lightGray
    }
    
    @IBAction func eraserButtonTapped() {
        sketchView.currentTool = .eraser
        pencilButton.tintColor = .lightGray
        eraserButton.tintColor = .systemBlue
    }
    
    @IBAction func clearButtonTapped() {
        sketchView.clearAllLayers()
    }
    
    @IBAction func brushWidthSliderChanged(_ sender: UISlider) {
        let sliderValue = sender.value
        sketchView.currentLineWidth = CGFloat(sliderValue)
        brushWidthButton.selectedWidth = CGFloat(sliderValue)
        brushWidthSliderValueLabel.text = "\(Int(sliderValue))"
        
        let slidertTrack : CGRect = sender.trackRect(forBounds: sender.bounds)
        let sliderFrm : CGRect = sender.thumbRect(forBounds: sender.bounds, trackRect: slidertTrack, value: sender.value)
        brushWidthSliderValueLabel.center = CGPoint(x: sliderFrm.origin.x + sender.frame.origin.x + sliderFrm.size.width / 2 + 16, y: sender.frame.origin.y - 40)
    }

    @IBAction func didEndEditBrushWidthSlider() {
        brushWidthSlider.isHidden = true
        brushWidthSliderValueLabel.isHidden = true
    }
}

// MARK: - ATSketchViewDelegate
extension TakeNoteViewController: ATSketchViewDelegate {
    func sketchViewOverridingRecognizedPathDrawing(_ sketchView: ATSketchView) -> UIBezierPath? {
        return nil
    }
    
    func sketchView(_ sketchView: ATSketchView, shouldAccepterRecognizedPathWithScore score: CGFloat) -> Bool {
        NSLog("Score: \(score)")
        if score >= 60 {
            NSLog("ACCEPTED")
            return true
        }
        NSLog("REJECTED")
        return false
    }
    
    func sketchView(_ sketchView: ATSketchView, didRecognizePathWithName name: String) {
        // We don't want to do anything here.
    }
    
    func sketchViewUpdatedUndoRedoState(_ sketchView: ATSketchView) {
        undoButton.isEnabled = sketchView.canUndo
        redoButton.isEnabled = sketchView.canRedo
        clearButton.isEnabled = sketchView.hasContent
    }
}

extension TakeNoteViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        brushColorButton.selectedColor = viewController.selectedColor
        sketchView.currentColor = viewController.selectedColor
    }
}
