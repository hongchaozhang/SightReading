//
//  EditTagViewController.swift
//  SightReading
//
//  Created by Zhang, Hongchao on 2021/1/29.
//

import Foundation
import UIKit

protocol EditTagViewControllerDelegate: class {
    func confirmEditingTags(with allTags: [String], selectedTags: [String], fileName: String)
}

class EditTagViewController: UIViewController {
    
    @IBOutlet weak var tagList: UITableView!
    @IBOutlet weak var tagInput: UITextField!
    
    var fileName = ""
    var allTags = [String]()
    var selectedTags = [String]()
    
    weak var delegate: EditTagViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tagList.delegate = self
        tagList.dataSource = self
    }
    
    @IBAction func doneButtonTapped() {
        delegate?.confirmEditingTags(with: allTags, selectedTags: selectedTags, fileName: fileName)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped() {
        if let newTag = tagInput.text, newTag != "" {
            if allTags.contains(newTag) {
                let alert = UIAlertController(title: "Warning", message: "The tag \(newTag) already exists.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            } else {
                allTags.append(newTag)
                selectedTags.append(newTag)
                tagList.reloadData()
            }
        }
    }
    
}

// MARK: - UITableViewDelegate
extension EditTagViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            if !selectedTags.contains(allTags[indexPath.row]) {
                selectedTags.append(allTags[indexPath.row])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
            if let index = selectedTags.firstIndex(of: allTags[indexPath.row]) {
                selectedTags.remove(at: index)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension EditTagViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "EditTagTableViewCell")
        if let _ = cell {

        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "EditTagTableViewCell")
        }
        
        let tag = allTags[indexPath.row]
        cell?.textLabel?.text = tag
        if selectedTags.contains(tag) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            cell?.accessoryType = .checkmark
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
            cell?.accessoryType = .none
        }
        return cell!
    }
    
    
}
