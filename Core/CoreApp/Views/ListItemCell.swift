//
//  ListItemCell.swift
//  Core
//
//  Created by LL on 7/20/22.
//

import Foundation
import UIKit
import SnapKit

class ListItemCell: UICollectionViewCell {

    var titleLabel: UILabel!
    var imageView: UIImageView!
    var identifier: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        titleLabel = UILabel()
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        titleLabel.textAlignment = .left
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        titleLabel.font = titleLabel.font.withSize(31)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.backgroundColor = .white
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().inset(5)
        }
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(40)
            make.left.bottom.right.equalToSuperview()
        }
    }

    func configure(text: String) {
        titleLabel.text = text
    }
}
