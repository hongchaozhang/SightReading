//
//  PhotoCollectionCell.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/18.
//

import Foundation
import UIKit

class PhotoCollectionCell: UICollectionViewCell {
    let imageView: UIImageView!
    override init(frame: CGRect) {
        imageView = UIImageView.init(frame: CGRect(origin: .zero, size: frame.size))
        super.init(frame: frame)
        self.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
