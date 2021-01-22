//
//  PhotoCollectionViewLayout.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import Foundation
import UIKit

class PhotoCollectionViewLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        itemSize = CGSize(width: photoCollectionWH, height: photoCollectionWH)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        itemSize = CGSize(width: photoCollectionWH, height: photoCollectionWH)
    }
}
