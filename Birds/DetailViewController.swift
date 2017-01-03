//
//  DetailViewController.swift
//  Birds
//
//  Created by Oliver Kulpakko on 2017-01-02.
//  Copyright © 2017 East Studios. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    var birdInfoVisible = false {
        didSet {
            if let descriptionView = self.birdDescriptionTextView {
                if birdInfoVisible {
                    infoButton.image = #imageLiteral(resourceName: "info-filled")
                    descriptionView.text = "Latin Name: \(detailItem!.latinName)\nEnglish Name: \(detailItem!.englishName)\nSwedish name: \(detailItem!.swedishName)\nCategory: \(detailItem!.category)\nCopyright: \(detailItem!.author)\nInternal ID: \(detailItem!.internalName)"
                } else {
                    infoButton.image = #imageLiteral(resourceName: "info")
                    descriptionView.text = detailItem!.description
                }
            }
        }
    }
    
    @IBOutlet weak var birdImageView: UIImageView!
    @IBOutlet weak var birdDescriptionTextView: UITextView!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var birdImageViewButton: UIButton!
    
    func configureView() {
        // Update the user interface for the detail item.
        if let selectedBird = self.detailItem {
            self.title = "\(selectedBird.finnishName)"
            if let descriptionView = self.birdDescriptionTextView {
                descriptionView.text = selectedBird.description
            }
            if let imageView = self.birdImageView {
                imageView.contentMode = .scaleAspectFit
                imageView.image = UIImage(named: "\(selectedBird.latinName).jpg")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    @IBAction func infoButtonTapped(_ sender: Any) {
        birdInfoVisible = !birdInfoVisible
    }

    @IBAction func birdImageViewButtonTapped(_ sender: Any) {
        let imageInfo = JTSImageInfo()
        imageInfo.image = birdImageView.image
        imageInfo.referenceRect = birdImageView.frame
        imageInfo.title = detailItem?.finnishName
        imageInfo.referenceView? = birdImageView
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .image, backgroundStyle: .blurred)
        imageViewer?.show(from: self, transition: .fromOffscreen)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: Bird? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }


}

