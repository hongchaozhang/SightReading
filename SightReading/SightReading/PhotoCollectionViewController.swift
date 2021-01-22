//
//  PhotoCollectionViewController.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import Foundation
import UIKit
import Photos

protocol PhotoCollectionViewControllerDelegate {
    func set(image: UIImage)
}

class PhotoCollectionViewController: UIViewController {
    let cellIdentifier = "COLLECTION_CELL_IDENTIFIER"
    var delegate: PhotoCollectionViewControllerDelegate?
    
    @IBOutlet weak var collection: UICollectionView!
    
    var allPhotos = PHFetchResult<PHAsset>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestPrivilegeAndLoadPhotos()
        
        collection.delegate = self
        collection.dataSource = self
        collection.register(PhotoCollectionCell.self, forCellWithReuseIdentifier: cellIdentifier)
    }
    
    private func requestPrivilegeAndLoadPhotos() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            loadPhotos()
        } else {
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    self.loadPhotos()
                    DispatchQueue.main.async {
                        self.collection.reloadData()
                    }
                } else {
                    // use not grant the privilege
                }
            }
        }
    }
    
    private func loadPhotos() {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        allPhotos = PHAsset.fetchAssets(with: .image, options: allPhotosOptions)
    }
}



extension PhotoCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("item: \(indexPath.item)")
        let assert = allPhotos.object(at: indexPath.item)
        PHImageManager.default().requestImage(for: assert, targetSize: CGSize(width: assert.pixelWidth, height: assert.pixelHeight), contentMode: .aspectFill, options: .none) { (image, dic) in
            if let image = image {
                self.delegate?.set(image: image)
            }
        }
        navigationController?.popViewController(animated: true)
    }
}

extension PhotoCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collection.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? PhotoCollectionCell {
            let assert = allPhotos.object(at: indexPath.item)
            PHImageManager.default().requestImage(for: assert, targetSize: CGSize(width: photoCollectionWH, height: photoCollectionWH), contentMode: .aspectFill, options: .none) { (image, dic) in
                if let image = image {
                    cell.imageView.image = image
                }
            }
            
            return cell
        } else {
            return collection.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        }
    }
    
    
}
