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
    @IBOutlet weak var birdImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var audioLabel: UILabel!
    @IBOutlet weak var topBlur: UIVisualEffectView!
    @IBOutlet weak var darkImageOverlay: UIView!
    @IBOutlet weak var latinNameLabel: UILabel!
    @IBOutlet weak var topBlurHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if UserDefaults.standard.bool(forKey: "hideBirdCategory") {
            topBlurHeight.constant = 3
            audioLabel.alpha = 0
            categoryLabel.alpha = 0
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
