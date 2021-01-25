//
//  ViewController.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sheetList: UITableView!
    let sheetListIdentifier = "SHEET_LIST_CELL"
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    var sheetNames = [String]()

//    let playVC = storyBoard.instantiateViewController(identifier: "Play")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        sheetList.delegate = self
        sheetList.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSheets()
        sheetList.reloadData()
        setTableViewEditMode(false)
    }
    
    private func loadSheets() {
        sheetNames = [String]()
        if let rootPath = Utility.getRootPath(),
           let enumerator = FileManager.default.enumerator(atPath: rootPath) {
            for filePath in enumerator {
                if let filePath = filePath as? String {
                    let strings = filePath.split(separator: ".")
                    if let fileNameSubSeqence = strings.first  {
                        let fileName = String(fileNameSubSeqence)
                        if fileName != "DS_Store" && !sheetNames.contains(fileName) {
                            sheetNames.append(fileName)
                        }
                    }
                }
            }
        }
    }
    
    private func setTableViewEditMode(_ isEditing: Bool) {
        if isEditing == true {
            self.sheetList.isEditing = true
            self.navigationItem.leftBarButtonItem?.title = "Done"
        } else {
            self.sheetList.isEditing = false
            self.navigationItem.leftBarButtonItem?.title = "Edit"
        }
    }

    @IBAction func editTapped(_ sender: Any) {
        if self.sheetList.isEditing == true {
            setTableViewEditMode(false)
        } else {
            setTableViewEditMode(true)
        }
    }
    @IBAction func addNewTapped(_ sender: UIBarButtonItem) {
        if let addNewVC = storyBoard.instantiateViewController(identifier: "AddNew") as? AddNewViewController {
            navigationController?.pushViewController(addNewVC, animated: true)
        }
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playVC = storyBoard.instantiateViewController(identifier: "Play")
        playVC.navigationItem.title = sheetNames[indexPath.row]
        navigationController?.pushViewController(playVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let rootPath = Utility.getRootPath() {
                let fileName = sheetNames[indexPath.row]
                try? FileManager.default.removeItem(atPath: "\(rootPath)/\(fileName).png")
                try? FileManager.default.removeItem(atPath: "\(rootPath)/\(fileName).json")
            }
            sheetNames.remove(at: indexPath.row)
            sheetList.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sheetNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = sheetList.dequeueReusableCell(withIdentifier: sheetListIdentifier)
        if let _ = cell {
            
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: sheetListIdentifier)
        }
        
        cell?.textLabel?.text = sheetNames[indexPath.row]
        
        return cell!
    }
    
    
}

