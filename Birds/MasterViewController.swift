//
//  MasterViewController.swift
//  Birds
//
//  Created by Oliver Kulpakko on 2017-01-02.
//  Copyright © 2017 East Studios. All rights reserved.
//

import UIKit
import SafariServices

class MasterViewController: UITableViewController, UISearchControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var copyrightInfoButton: UIBarButtonItem!
    @IBOutlet weak var historyButton: UIBarButtonItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    var canShowHistory = false {
        didSet {
            historyButton.isEnabled = canShowHistory
        }
    }
    var shouldShowHistory = false {
        didSet {
            performSegue(withIdentifier: "showDetail", sender: self)
            shouldShowHistory = false
        }
    }
    var detailViewController: DetailViewController? = nil
    var birds = [Bird]()
    var favorites = [Bird]()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredBirds = [Bird]()
    var allDownloaded = false
    var isDownloading = false {
        didSet {
            tableView.reloadEmptyDataSet()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        #if DEBUG
            //Don't use cached json when debugging
            URLCache.shared.removeAllCachedResponses()
        #endif
        getBirds()
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        
        searchController.searchBar.scopeButtonTitles = [NSLocalizedString("All", comment: "In search bar's scope, 'All Categories'"), "Sorsalinnut", "Kahlaajat", "Pöllöt", "Rastaat"]
        searchController.searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        canShowHistory = UserDefaults.standard.integer(forKey: "lastBird") > 0
        if allDownloaded {
            updateCell(path: UserDefaults.standard.integer(forKey: "lastBird"))
        }
        refreshFavorites()
    }
    
    func updateCell(path: Int) {
        let indexPath = NSIndexPath(item: path, section: 1)
        
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.none)
        tableView.endUpdates()
    }
    
    func refreshFavorites() {
        var index = 0
        tableView.beginUpdates()
        self.favorites = []
        for _ in birds {
            let newBird = birds[index]
            index += 1
            if (newBird.isFavorite) {
                self.favorites.append(newBird)
                UserDefaults.standard.set(true, forKey: "isFavorite-\(newBird.internalName)")
            }
        }
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        tableView.endUpdates()
    }
    
        override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getBirds() {
        birds = []
        isDownloading = true
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        if let url = NSURL(string: "https://eaststudios.fi/api/BirdsFI/v1/getBirds?appVersion=\(appVersion)") {
            session.dataTask(with: url as URL, completionHandler: { (data, response, error) -> Void in
                if error != nil {
                    self.isDownloading = false
                    print("Can't get Birds. Error: \(error!)")
                    return
                } else if let jsonData = data {
                    do {
                        let parsedJSON = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String:AnyObject]
                        guard let results = parsedJSON["birds"] as? [[String:AnyObject]] else { return }
                        for result in results {
                            let newBird = Bird()
                            newBird.internalName = result["internalName"] as! String
                            newBird.mapID = self.getMapID(bird: newBird)
                            newBird.latinName = result["latinName"] as! String
                            newBird.englishName = result["englishName"] as! String
                            newBird.finnishName = result["finnishName"] as! String
                            newBird.category = result["category"] as! String
                            newBird.swedishName = result["swedishName"] as! String
                            newBird.description = result["description"] as! String
                            newBird.author = result["author"] as! String
                            newBird.hasAudio = self.birdHasAudio(bird: newBird)
                            newBird.allDetails = "\(newBird.internalName)\(newBird.latinName)\(newBird.englishName)\(newBird.finnishName)\(newBird.swedishName)\(newBird.category)"
                            
                            if (UserDefaults.standard.bool(forKey: "isFavorite-\(newBird.internalName)")) {
                                newBird.isFavorite = true
                                self.favorites.append(newBird)
                            }
                            
                            self.birds.append(newBird)
                        }
                        DispatchQueue.main.async {
                            if UserDefaults.standard.integer(forKey: "sortBy") == 1 {
                                self.birds.sort(by: { $0.category < $1.category })
                            } else {
                                self.birds.sort(by: { $0.finnishName < $1.finnishName })
                            }
                            
                            self.tableView.reloadData()
                            self.detailViewController?.detailItem = self.birds[0]
                            self.isDownloading = false
                            self.allDownloaded = true
                        }
                        
                    } catch let error as NSError {
                        self.isDownloading = false
                        print(error)
                    }
                }
            }).resume()
        }
    }
    
    func getMapID(bird: Bird) -> Int {
        //TODO: Remove hard-coding and load from file.
        var dictionary: [String:Int] =
            ["CYGOLO": 107, "CYGCOL": 108, "CYGCYG": 109, "ANSFAB": 110, "ANSBRA": 111, "ANSALB": 112, "ANSANS": 114, "ANSCAE": 115, "BRACAN": 116, "BRALEU": 117, "BRABER": 118, "BRARUF": 119, "TADFER": 120, "TADTAD": 121, "AIXGAL": 122, "ANAPEN": 123, "ANAAME": 124, "ANASTR": 125, "ANACRE": 126, "ANACAR": 127, "ANAPLA": 128, "ANAACU": 129, "ANAQUE": 130, "ANADIS": 131, "ANACLY": 132, "NETRUF": 133, "AYTFER": 134, "AYTCOL": 135, "AYTFUL": 137, "AYTMAR": 138, "SOMMOL": 139, "SOMSPE": 140, "POLSTE": 141, "CLAHYE": 143, "MELNIG": 144, "MELPER": 145, "MELFUS": 146, "BUCCLA": 147, "MERALB": 148, "MERSER": 149, "MERMER": 150, "OXYJAM": 151, "BONBON": 152, "LAGLAG": 153, "LAGMUT": 154, "TETRIX": 155, "TETURO": 156, "PERPER": 157, "COTCOT": 158, "PHACOL": 159, "GAVSTE": 160, "GAVARC": 161, "GAVIMM": 162, "GAVADA": 163, "TACRUF": 164, "PODCRI": 165, "PODGRI": 166, "PODAUR": 167, "PHACAR": 176, "BOTSTE": 179, "EGRGAR": 184, "EGRALB": 185, "ARDCIN": 186, "CICNIG": 188, "CICCIC": 189, "PERAPI": 192, "CIRGAL": 199, "CIRAER": 200, "CIRCYA": 201, "ACCGEN": 204, "ACCNIS": 205, "BUTBUT": 206, "BUTRUF": 207, "BUTLAG": 208, "PANHAL": 215]
        if let number = dictionary[bird.internalName] {
            return number
        }
        return 0
    }
    
    func birdHasAudio(bird: Bird) -> Bool {
        guard let path = Bundle.main.path(forResource: "\(bird.internalName)", ofType: "mp3") else {
            return false
        }
        return FileManager.default.fileExists(atPath: path)
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if shouldShowHistory {
                let indexPath = UserDefaults.standard.integer(forKey: "lastBird")
                let selectedBird: Bird
                selectedBird = birds[indexPath]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = selectedBird
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                return
            }
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let selectedBird: Bird
                if searchController.isActive && searchController.searchBar.text != "" {
                    if indexPath.section == 0 {
                        selectedBird = favorites[indexPath.row]
                    } else {
                        selectedBird = filteredBirds[indexPath.row]
                    }
                    //TODO: Can't use history if using search
                    UserDefaults.standard.set(-1, forKey: "lastBird")
                } else if indexPath.section == 0 {
                    selectedBird = favorites[indexPath.row]
                } else {
                    selectedBird = birds[indexPath.row]
                    UserDefaults.standard.set(indexPath.row, forKey: "lastBird")
                }
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = selectedBird
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: - Table View
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && self.favorites.count < 1 {
            return 0
        }
        if self.birds.count < 1 {
            return 0
        }
        return 20
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red:0.07, green:0.12, blue:0.12, alpha:1.0)
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
        header.alpha = 0.65
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return favorites.count
        default:
            if searchController.isActive && searchController.searchBar.text != "" {
                return filteredBirds.count
            }
            return birds.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "\(NSLocalizedString("Favorites", comment: "Section title for favorites")) (\(favorites.count))"
        default:
            return NSLocalizedString("Birds", comment: "Section title for birds")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let bird: Bird
        if searchController.isActive && searchController.searchBar.text != "" {
            if indexPath.section == 0 {
                bird = favorites[indexPath.row]
            } else {
                bird = filteredBirds[indexPath.row]
            }
        } else if indexPath.section == 0 {
            bird = favorites[indexPath.row]
        } else {
            bird = birds[indexPath.row]
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        cell.nameLabel.text = bird.finnishName
        cell.categoryLabel.text = bird.category
        cell.bird = bird
        cell.audioLabel.isHidden = !bird.hasAudio
        let image = UIImage(named: "LR_\(bird.latinName).jpg")
        cell.birdImageView?.image = self.cropImageToSquare(image: image!)
        if bird.isFavorite {
            cell.nameLabel.text = "♥ \(bird.finnishName)"
        }
        return cell
    }
    
    func filterContentForSearchText(searchText: String, scope: String = NSLocalizedString("All", comment: "In search bar's scope, 'All Categories'")) {
        filteredBirds = birds.filter { bird in
            let categoryMatch = (scope == NSLocalizedString("All", comment: "In search bar's scope, 'All Categories'")) || (bird.category == scope)
            return  categoryMatch && bird.allDetails.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.text = ""
        refreshFavorites()
        tableView.reloadData()
    }
    
    @IBAction func showCopyrightInfo(_ sender: Any) {
        let svc = SFSafariViewController(url: NSURL(string: "https://eaststudios.fi/birdsFI/copyrightInfo.html")! as URL)
        self.present(svc, animated: true, completion: nil)
    }
    @IBAction func openSettings(_ sender: Any) {
        UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString) as! URL)
    }
    
    @IBAction func showLastBird(_ sender: Any) {
        if UserDefaults.standard.integer(forKey: "lastBird") > 0 {
            shouldShowHistory = true
        }
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
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        var str = NSLocalizedString("Can't download Birds", comment: "Error title when birds weren't downloaded succesfully.")
        if searchController.isActive && searchController.searchBar.text != "" {
            str = NSLocalizedString("No Results", comment: "Error title when no search results were found.")
        } else if isDownloading {
            str = NSLocalizedString("Downloading...", comment: "Progress title when birds are being downloaded.")
        }
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        var str = "Please check your internet connection."
        if searchController.isActive && searchController.searchBar.text != "" {
            str = NSLocalizedString("Can't find any birds matching", comment: "Error message when no search results were found.") + " '\(searchController.searchBar.text!)'."
        } else if isDownloading {
            str = NSLocalizedString("Is this taking too long? Close the app and try again.", comment: "Progress message when birds are being downloaded.")
        }
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "searchPlaceholder")
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -(navigationController?.navigationBar.bounds.height)!
    }

}
extension MasterViewController: UISearchResultsUpdating {
    @available(iOS 8.0, *)
    public func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchText: searchController.searchBar.text!, scope: scope)
    }
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        //remove favorites
        tableView.beginUpdates()
        self.favorites = []
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        tableView.endUpdates()
        return true
    }
}
extension MasterViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchText: searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}
