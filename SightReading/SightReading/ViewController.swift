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

    override func viewDidLoad() {
        super.viewDidLoad()
        fileTableView.delegate = self
        fileTableView.dataSource = self
        setupTagSelector()
        setupSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFileNames()
        loadTags()
        fileTableView.reloadData()
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
    private func loadFileNames() {
        allFileNames = [String]()
        if let rootPath = Utility.getRootPath(),
           let enumerator = FileManager.default.enumerator(atPath: rootPath) {
            for filePath in enumerator {
                if let filePath = filePath as? String {
                    let strings = filePath.split(separator: ".")
                    if let fileNameSubSeqence = strings.first  {
                        let originFileName = String(fileNameSubSeqence)
                        let fileName = originFileName.replacingOccurrences(of: noteImageSubfix, with: "", options: .backwards, range: nil)
                        if fileName != "DS_Store" && !allFileNames.contains(fileName) {
                            allFileNames.append(fileName)
                        }
                    }
                }
            }
        }
        allFileNames.sort()
    }
    
    private func loadTags() {
        if let allTags = UserDefaults.standard.value(forKey: allTagsKey) as? [String] {
            self.allTags = allTags.sorted()
            allTagsForSelector = allTags.sorted()
            allTagsForSelector.insert(allTagConstant, at: 0)
        }
        for fileName in allFileNames {
            if let fileTags = UserDefaults.standard.value(forKey: fileName) as? [String] {
                allFileTags[fileName] = fileTags.sorted()
            }
        }
    }
    
    // MARK: - button callbacks
    @IBAction func addNewTapped(_ sender: UIBarButtonItem) {
        if let addNewVC = storyBoard.instantiateViewController(identifier: "AddNew") as? AddNewViewController {
            navigationController?.pushViewController(addNewVC, animated: true)
        }
    }
    
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playVC = storyBoard.instantiateViewController(identifier: "Play")
        playVC.navigationItem.title = filtedFileNames[indexPath.row]
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
    
    private func deleteItem(at indexPath: IndexPath) {
        if let rootPath = Utility.getRootPath() {
            let fileName = filtedFileNames[indexPath.row]
            try? FileManager.default.removeItem(atPath: "\(rootPath)/\(fileName).png")
            try? FileManager.default.removeItem(atPath: "\(rootPath)/\(fileName).json")
            UserDefaults.standard.removeObject(forKey: fileName)
        }
        allFileNames.remove(at: indexPath.row)
        fileTableView.deleteRows(at: [indexPath], with: .fade)
        fileTableView.reloadData()
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
        
        cell?.textLabel?.text = filtedFileNames[indexPath.row]
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
        if allTags.count > 0 {
            UserDefaults.standard.setValue(allTags, forKey: allTagsKey)
        }
        if selectedTags.count > 0 {
            UserDefaults.standard.setValue(selectedTags, forKey: fileName)
        }
        
        self.allTags = allTags
        self.allTagsForSelector = allTags
        self.allTagsForSelector.insert(allTagConstant, at: 0)
        self.allFileTags[fileName] = selectedTags
        self.fileTableView.reloadData()
    }
}

