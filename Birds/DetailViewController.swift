//
//  DetailViewController.swift
//  Birds
//
//  Created by Oliver Kulpakko on 2017-01-02.
//  Copyright © 2017 East Studios. All rights reserved.
//

import UIKit
import AVFoundation

class DetailViewController: UIViewController, AVAudioPlayerDelegate {
    var birdInfoVisible = false {
        didSet {
            if let descriptionView = self.birdDescriptionTextView {
                if birdInfoVisible {
                    infoButton.image = #imageLiteral(resourceName: "info-filled")
                    descriptionView.textAlignment = .natural
                    descriptionView.text =
                        NSLocalizedString("Latin Name", comment: "Latin Name in Description view") +
                        ": \(detailItem!.latinName)\n" +
                        NSLocalizedString("English Name", comment: "English Name in Description view") +
                        ": \(detailItem!.englishName)\n" +
                        NSLocalizedString("Swedish Name", comment: "Swedish Name in Description view") +
                        ": \(detailItem!.swedishName)\n" +
                        NSLocalizedString("Category", comment: "Category in Description view") +
                        ": \(detailItem!.category)\n" +
                        NSLocalizedString("Copyright", comment: "Copyright in Description view") +
                        ": \(detailItem!.author)\n"
                } else {
                    descriptionView.textAlignment = .center
                    infoButton.image = #imageLiteral(resourceName: "info")
                    descriptionView.text = detailItem!.description
                }
            }
        }
    }
    
    var debugMode = false {
        didSet {
            birdInfoVisible = true
            birdDescriptionTextView.text.append(
                NSLocalizedString("Has Audio", comment: "Has Audio in Description view") +
                ": \(detailItem!.hasAudio)\n" +
                NSLocalizedString("Is Favorite", comment: "Is Favorite in Description view") +
                ": \(detailItem!.isFavorite)\n" +
                NSLocalizedString("Internal ID", comment: "Internal ID in Description view") +
            ": \(detailItem!.internalName)")
        }
    }
    var player : AVAudioPlayer! = nil
    var isPlaying = false {
        didSet {
            if isPlaying {
                soundButton.image = #imageLiteral(resourceName: "stop")
            } else {
                soundButton.image = #imageLiteral(resourceName: "play")
                player.stop()
            }
        }
    }
    
    @IBOutlet weak var soundButton: UIBarButtonItem!
    @IBOutlet weak var showMapImageButton: UIBarButtonItem!
    @IBOutlet weak var birdImageView: UIImageView!
    @IBOutlet weak var birdDescriptionTextView: UITextView!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var birdImageViewButton: UIButton!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configureView() {
        // Update the user interface for the detail item.
        if let selectedBird = self.detailItem {
            showMapImageButton.isEnabled = selectedBird.mapID > 0
            soundButton.isEnabled = selectedBird.hasAudio
            if let nLabel = self.nameLabel {
                nLabel.text = "\(selectedBird.finnishName)"
            }
            if let descriptionView = self.birdDescriptionTextView {
                descriptionView.isScrollEnabled = false
                descriptionView.text = selectedBird.description
            }
            if let imageView = self.birdImageView {
                imageView.contentMode = .scaleAspectFit
                imageView.image = UIImage(named: "LR_\(selectedBird.latinName).jpg")
                imageView.imageFromServerURL(urlString: "https://eaststudios.fi/api/BirdsFI/v1/images/\(selectedBird.latinName).jpg".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)

            }
            if let imageButton = self.birdImageViewButton {
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
                longPress.minimumPressDuration = 3
                imageButton.addGestureRecognizer(longPress)
            }
            if selectedBird.isFavorite {
                favoriteButton.image = #imageLiteral(resourceName: "favorite-filled")
            } else {
                favoriteButton.image = #imageLiteral(resourceName: "favorite")
            }
        } else {
            if let nLabel = self.nameLabel {
                nLabel.text = NSLocalizedString("No Bird Selected", comment: "Placeholder title in detail View")
            }
            if let descriptionView = self.birdDescriptionTextView {
                descriptionView.text = NSLocalizedString("Select a Bird from Left", comment: "Placeholder text in detail View")
            }
        }
    }

    func longPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .recognized  {
            debugMode = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let descriptionView = self.birdDescriptionTextView {
            descriptionView.isScrollEnabled = true
        }
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
    
    @IBAction func showMapImage(_ sender: Any) {
        //TODO: Load maps natively on MKMapView with topo maps overlay.
        var url = "http://atlas3.lintuatlas.fi/kartat-atlas/taxonmap.php?taxon=\(detailItem!.mapID)&style=4&size=1&theme="
        if (UserDefaults.standard.bool(forKey: "showClearance")) {
            url = url + "sel_dicromacy"
        } else {
            url = url + "sel_white"
        }
        let imageInfo = JTSImageInfo()
        imageInfo.imageURL = URL(string: url)
        imageInfo.referenceRect = self.view.frame
        imageInfo.title = detailItem?.finnishName
        imageInfo.referenceView? = self.view
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .image, backgroundStyle: .blurred)
        imageViewer?.show(from: self, transition: .fromOffscreen)
    }
    
    @IBAction func listenSound(_ sender: Any) {
        if !isPlaying {
            isPlaying = !isPlaying
            if let item = detailItem {
                if let path = Bundle.main.path(forResource: ("\(item.internalName)"), ofType:"mp3") {
                    do {
                        let fileURL = NSURL(fileURLWithPath: path)
                        try player = AVAudioPlayer(contentsOf: fileURL as URL)
                        player.prepareToPlay()
                        player.delegate = self
                        player.play()
                    } catch {
                        soundButton.isEnabled = false
                    }
                } else {
                    soundButton.isEnabled = false
                }
            } else {
                soundButton.isEnabled = false
            }
        } else {
            isPlaying = !isPlaying
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
    
    @IBAction func addToFavorites(_ sender: Any) {
        if !(UserDefaults.standard.value(forKey: "favoriteCount") != nil) {
            UserDefaults.standard.set(0, forKey: "favoriteCount")
        }
        var favoriteCount = 0
        favoriteCount = (UserDefaults.standard.value(forKey: "favoriteCount") as? Int)!
        
        if (detailItem?.isFavorite)! {
            detailItem?.isFavorite = false
            UserDefaults.standard.set(false, forKey: "isFavorite-\(detailItem!.internalName)")
            UserDefaults.standard.set(favoriteCount - 1, forKey: "favoriteCount")
            favoriteButton.image = #imageLiteral(resourceName: "favorite")
        } else {
            detailItem?.isFavorite = true
            UserDefaults.standard.set(true, forKey: "isFavorite-\(detailItem!.internalName)")
            UserDefaults.standard.set(favoriteCount + 1, forKey: "favoriteCount")
            favoriteButton.image = #imageLiteral(resourceName: "favorite-filled")
        }
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
extension UIImageView {
    public func imageFromServerURL(urlString: String) {
        
        URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                print(error ?? "Can't load picture")
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                let image = UIImage(data: data!)
                self.image = image
            })
            
        }).resume()
    }}
