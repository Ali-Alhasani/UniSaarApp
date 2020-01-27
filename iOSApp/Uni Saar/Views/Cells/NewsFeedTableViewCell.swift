//
//  NewsFeedTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import AlamofireImage
class NewsFeedTableViewCell: UITableViewCell {
    @IBOutlet weak var newsDateLabel: UILabel!
    @IBOutlet weak var newsTitleLabel: UILabel!
    @IBOutlet weak var newsSubTitleLabel: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var outerView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        outerView.setAsCircle(cornerRadius: 4)
        outerView.setAllSideShadow(shadowOpacity: 0.8)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    override func prepareForReuse() {
        newsImageView.af_cancelImageRequest()
        newsImageView.image = nil
    }
}

extension NewsFeedTableViewCell: NewsFeedViewModelView {
    var titleLabel: UILabel? {
        return newsTitleLabel
    }
    var subTitleLabel: UILabel? {
        return newsSubTitleLabel
    }
    var dateLabel: UILabel? {
        return newsDateLabel
    }
}
