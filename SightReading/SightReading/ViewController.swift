//
//  ViewController.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import UIKit

class ViewController: UIViewController {
    let allTagsKey = "ALL_TAGS"
    var allTags = [String]()
    var allFileTags = [String: [String]]()
    
    @IBOutlet weak var fileTableView: UITableView!
    let fileTableViewCellIdentifier = "FILE_TABLE_VIEW_CELL"
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    var fileNames = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        fileTableView.delegate = self
        fileTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFileNames()
        loadTags()
        fileTableView.reloadData()
    }
    
    private func loadFileNames() {
        fileNames = [String]()
        if let rootPath = Utility.getRootPath(),
           let enumerator = FileManager.default.enumerator(atPath: rootPath) {
            for filePath in enumerator {
                if let filePath = filePath as? String {
                    let strings = filePath.split(separator: ".")
                    if let fileNameSubSeqence = strings.first  {
                        let fileName = String(fileNameSubSeqence)
                        if fileName != "DS_Store" && !fileNames.contains(fileName) {
                            fileNames.append(fileName)
                        }
                    }
                }
            }
        }
        fileNames.sort()
    }
    
    private func loadTags() {
        if let allTags = UserDefaults.standard.value(forKey: allTagsKey) as? [String] {
            self.allTags = allTags
        }
        for fileName in fileNames {
            if let fileTags = UserDefaults.standard.value(forKey: fileName) as? [String] {
                allFileTags[fileName] = fileTags
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
        playVC.navigationItem.title = fileNames[indexPath.row]
        navigationController?.pushViewController(playVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    private func editTags(for indexPath: IndexPath) {
        if let tagVCOption = storyboard?.instantiateViewController(identifier: "Tags"),
           let tagVC = tagVCOption as? EditTagViewController {
            tagVC.fileName = fileNames[indexPath.row]
            tagVC.allTags = allTags
            if let fileTags = allFileTags[fileNames[indexPath.row]] {
                tagVC.selectedTags = fileTags
            }
            tagVC.delegate = self
            self.present(tagVC, animated: true, completion: nil)
        }
    }
    
    private func deleteItem(at indexPath: IndexPath) {
        if let rootPath = Utility.getRootPath() {
            let fileName = fileNames[indexPath.row]
            try? FileManager.default.removeItem(atPath: "\(rootPath)/\(fileName).png")
            try? FileManager.default.removeItem(atPath: "\(rootPath)/\(fileName).json")
            UserDefaults.standard.removeObject(forKey: fileName)
        }
        fileNames.remove(at: indexPath.row)
        fileTableView.deleteRows(at: [indexPath], with: .fade)
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
        return fileNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = fileTableView.dequeueReusableCell(withIdentifier: fileTableViewCellIdentifier)
        if let _ = cell {
            
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: fileTableViewCellIdentifier)
        }
        
        cell?.textLabel?.text = fileNames[indexPath.row]
        cell?.detailTextLabel?.text = getTagListString(for: fileNames[indexPath.row])
        
        return cell!
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
        self.allFileTags[fileName] = selectedTags
        self.fileTableView.reloadData()
    }
}

