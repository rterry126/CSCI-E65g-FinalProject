//
//  History_master.swift
//  Final_Project
//
//  Created by Robert Terry on 11/10/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - https://code.tutsplus.com/tutorials/getting-started-with-cloud-firestore-for-ios--cms-30910
// Sources - Date Formatting - https://stackoverflow.com/questions/35700281/date-format-in-swift

import UIKit
import Firebase

// This is mostly code from the restaurant bill table view controller modified for this use, plus heavy
// use of tutorial from above and Google Firestore examples...

class GameHistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var dateTime: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var playerOneName: UILabel!
    @IBOutlet weak var playerTwoName: UILabel!
    @IBOutlet weak var playerOneScore: UILabel!
    @IBOutlet weak var playerTwoScore: UILabel!
    @IBOutlet weak var gameView: UIImageView!
    
}


//MARK: -
class HistoryMasterViewController: UIViewController {
    
    public var games: [Game] = []
    
    var sharedFirebaseProxy: FirebaseProxy = {
        Util.log("HistoryMasterVC ==> FirebaseProxy: get Singleton")
        return FirebaseProxy.instance
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
       
            // Retrieve data for table asychronously. Reload table when results are returned
            sharedFirebaseProxy.downloadHistory() { resultsArray, error in
                if let error = error {
                    Util.log("\(error.localizedDescription)")
                    return
                }
                
                self.games = resultsArray
                self.gameHistoryTableView.reloadData()
            }

    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.listener.remove()
    }
    
    
    let tableSections = 1
    
    //MARK: - Methods
    
    func updateUI() {}
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var gameHistoryTableView: UITableView!
    
    
    
    // MARK: - Segues
    //TODO: - Source Master-Detail project starter code.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueHistoryDetail" {
            if let indexPath = gameHistoryTableView.indexPathForSelectedRow {
                let game = games[indexPath.row].playerOneName
//                let game2 = games[indexPath.row].gameBoard
                let detailVC = /*(segue.destination as! UINavigationController).topViewController*/ segue.destination as? HistoryDetailVC
                detailVC?.username = game
//                detailVC?.gameBoard = game2
//                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
 
    
    
}


// MARK: - Table View code: Datasource
extension HistoryMasterViewController: UITableViewDataSource {
    
    func numberOfSections(in gameHistoryTableView: UITableView) -> Int {
        return tableSections // 'tableSections' is a Created class constant
    }
    
    
    // Number of row, which will be the query limit, currently 10.
    func tableView(_ gameHistoryTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Number of history items retrieved
        return games.count
    }
    
    
    // Actually populate the table, cell by cell
    func tableView(_ gameHistoryTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // The 'dequeue' code for custom cell includes an as?, in case it can't cast as the custom cell class.
        // A more robust implementation would be to fall back to a non-custom cell vice throwing an error.
        // Source cited for as?
       // 1) Build the custom cell
        guard let cell = gameHistoryTableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as? GameHistoryTableViewCell  else {
            fatalError("Cannot create custom table view cell!")
        }
        
        // 2) Get each game history (single game)
        let singleGame = games[indexPath.row]
        

        // Setup formatting for game Date and Time
        let dateFormatter = DateFormatter()
        let timeFormatter = DateFormatter()

        dateFormatter.dateFormat = "MM/dd/yy"
        timeFormatter.dateFormat = "HH:mm"
        
        let image = UIImage(data: singleGame.gameBoardView)
        print("image converted from data downloaded")
        
        
        // 3) Populate the cell
        
        // Firestore stores as a 'Timestamp'. Game date/time is stored in model as type 'Any' so
        // I need to cast first to a Timestamp here and then convert to Swift Date object
        if let timestamp = singleGame.gameDate as? Timestamp {
            let date: Date = timestamp.dateValue()
            
            cell.dateTime.text = dateFormatter.string(from: date)
            cell.time.text = timeFormatter.string(from: date)
        }
        
        cell.playerOneName.text = singleGame.playerOneName
        cell.playerOneScore.text = singleGame.playerOneScore.description
        cell.playerTwoName.text = singleGame.playerTwoName
        cell.playerTwoScore.text = singleGame.playerTwoScore.description
        cell.gameView.image = image


        // Return it to iOS to render
        return cell
    }
    
    
    // Select a row and segue to the detail page
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//
//        //TODO: - Fix this for better nameing later
//        let tempVariable = games[indexPath.row].playerOneName
//        print(tempVariable)
//        self.performSegue(withIdentifier: "segueHistoryDetail", sender: tempVariable)
//    }
    
    
    // Allow Deletion
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Actually delete. Firestore takes care of caching deletes IF we are off line. Sweet.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete){
            let singeGameToDelete = games[indexPath.row]
            _ = Firestore.firestore().collection("history_test").document(singeGameToDelete.id).delete()
        }
    }
}
