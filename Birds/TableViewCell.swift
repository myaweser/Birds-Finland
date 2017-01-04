//
//  TableViewCell.swift
//  Birds
//
//  Created by Oliver Kulpakko on 2017-01-03.
//  Copyright © 2017 East Studios. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    var bird: Bird!
    @IBOutlet weak var birdImageButton: UIButton!
    @IBOutlet weak var birdImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var audioLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func birdImageButtonTapped(_ sender: Any) {
        let imageInfo = JTSImageInfo()
        imageInfo.image = UIImage(named: "\(bird.latinName).jpg")
        imageInfo.referenceRect = birdImageView.frame
        imageInfo.title = nameLabel.text
        imageInfo.referenceView = birdImageView
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .image, backgroundStyle: .blurred)
        imageViewer?.show(from: UIApplication.shared.keyWindow?.rootViewController, transition: .fromOriginalPosition)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
