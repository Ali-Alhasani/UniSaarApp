//
//  NewsFeedTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import AlamofireImage
import UIKit

class NewsFeedTableViewCell: UITableViewCell {
    @IBOutlet var newsDateLabel: UILabel!
    @IBOutlet var newsTitleLabel: UILabel!
    @IBOutlet var newsSubTitleLabel: UILabel!
    @IBOutlet var newsImageView: UIImageView!
    @IBOutlet var outerView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            outerView.setAsCircle(cornerRadius: 4)
            outerView.setAllSideShadow(shadowOpacity: 0.8)
        }
    }

    override func prepareForReuse() {
        newsImageView.af.cancelImageRequest()
        newsImageView.image = nil
    }
}

extension NewsFeedTableViewCell: NewsFeedViewModelView {
    var titleLabel: UILabel? {
        newsTitleLabel
    }

    var subTitleLabel: UILabel? {
        newsSubTitleLabel
    }

    var dateLabel: UILabel? {
        newsDateLabel
    }
}
