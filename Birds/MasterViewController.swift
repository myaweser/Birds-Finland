//
//  MasterViewController.swift
//  Birds
//
//  Created by Oliver Kulpakko on 2017-01-02.
//  Copyright © 2017 East Studios. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UISearchControllerDelegate {
    
    var detailViewController: DetailViewController? = nil
    var birds = [Bird]()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredBirds = [Bird]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        getBirds()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getBirds() {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        if let url = NSURL(string: "https://eaststudios.fi/api/BirdsFI/v1/getBirds") {
            session.dataTask(with: url as URL, completionHandler: { (data, response, error) -> Void in
                if error != nil {
                    print("Can't get Birds. Error: \(error!)")
                    return
                } else if let jsonData = data {
                    do {
                        let parsedJSON = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String:AnyObject]
                        guard let results = parsedJSON["birds"] as? [[String:AnyObject]] else { return }
                        for result in results {
                            let newBird = Bird()
                            newBird.internalName = result["internalName"] as! String
                            newBird.latinName = result["latinName"] as! String
                            newBird.englishName = result["englishName"] as! String
                            newBird.finnishName = result["finnishName"] as! String
                            newBird.swedishName = result["swedishName"] as! String
                            newBird.description = result["description"] as! String
                            newBird.author = result["author"] as! String
                            
                            self.birds.append(newBird)
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                        
                    } catch let error as NSError {
                        print(error)
                    }
                }
            }).resume()
        }
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let selectedBird: Bird
                if searchController.isActive && searchController.searchBar.text != "" {
                    selectedBird = filteredBirds[indexPath.row]
                } else {
                    selectedBird = birds[indexPath.row]
                }
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = selectedBird
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredBirds.count
        }
        return birds.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let bird: Bird
        if searchController.isActive && searchController.searchBar.text != "" {
            bird = filteredBirds[indexPath.row]
        } else {
            bird = birds[indexPath.row]
        }
        
        cell.textLabel!.text = bird.finnishName
        
        let image = UIImage(named: "\(bird.latinName).jpg")
        cell.imageView?.image = self.cropImageToSquare(image: image!)
        return cell
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredBirds = birds.filter { bird in
            return bird.finnishName.lowercased().contains(searchText.lowercased())
        }
        
        tableView.reloadData()
    }
    
    func cropImageToSquare(image: UIImage) -> UIImage? {
        var imageHeight = image.size.height
        var imageWidth = image.size.width
        
        if imageHeight > imageWidth {
            imageHeight = imageWidth
        } else {
            imageWidth = imageHeight
        }
        
        let size = CGSize(width: imageWidth, height: imageHeight)
        
        let refWidth : CGFloat = CGFloat(image.cgImage!.width)
        let refHeight : CGFloat = CGFloat(image.cgImage!.height)
        
        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2
        
        let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
        if let imageRef = image.cgImage!.cropping(to: cropRect) {
            return UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
        }
        
        return nil
    }
}
extension MasterViewController: UISearchResultsUpdating {
    @available(iOS 8.0, *)
    public func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
