//
//  History_master.swift
//  Final_Project
//
//  Created by Robert Terry on 11/10/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - https://code.tutsplus.com/tutorials/getting-started-with-cloud-firestore-for-ios--cms-30910
// Sources - Date Formatting - https://stackoverflow.com/questions/35700281/date-format-in-swift
// Sources - UISwitch - https://stackoverflow.com/questions/48623771/loading-ison-or-isoff-for-a-uiswitch-using-swift-4
// Sources - local or cloud storage - https://firebase.google.com/docs/firestore/manage-data/enable-offline

import UIKit
import Firebase

// This is mostly code from the restaurant bill table view controller modified for this use, plus heavy
// use of tutorial from above and Google Firestore examples...

class GameHistoryTableViewCell: UITableViewCell {
    
    // MARK: - Cell Outlets
    @IBOutlet weak var dateTime: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var playerOneName: UILabel!
    @IBOutlet weak var playerTwoName: UILabel!
    @IBOutlet weak var playerOneScore: UILabel!
    @IBOutlet weak var playerTwoScore: UILabel!
    @IBOutlet weak var gameView: UIImageView!
    
    
}


class HistoryMasterViewController: UIViewController {
    
    public var games: [Game] = []
    let tableSections = 1
    
    @IBOutlet weak var gameHistoryTableView: UITableView!
    
    
    var sharedFirebaseProxy: FirebaseProxy = {
        Util.log("HistoryMasterVC ==> FirebaseProxy: get Singleton")
        return FirebaseProxy.instance
    }()
    
    var modelGamePrefs: GamePrefModelProtocol = {
        Util.log("HistoryVC ==> Preferences Model: instantiate")
        return GamePrefModel.instance
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // So this was a last minute not well thought out option to let user determine where history was stored
    // in Google, or locally. UISwitch in Preferences. While it temporarily works here, network access
    // is turned back on in viewWillDisappear. Firestore is smart enough to sync at that point even
    // though view is not active. 
    override func viewWillAppear(_ animated: Bool) {
        
        if modelGamePrefs.localHistory {
            Firestore.firestore().disableNetwork { (error) in
                // Do offline things
                // ...
                // Retrieve data for table asychronously. Reload table when results are returned
                self.sharedFirebaseProxy.downloadHistory() { resultsArray, error in
                    if let error = error {
                        Util.log("\(error.localizedDescription)")
                        return
                    }
                    self.games = resultsArray
                    self.gameHistoryTableView.reloadData()
                }
            }
        }
        else {
            // Retrieve data for table asychronously. Reload table when results are returned
            self.sharedFirebaseProxy.downloadHistory() { resultsArray, error in
                if let error = error {
                    Util.log("\(error.localizedDescription)")
                    return
                }
                self.games = resultsArray
                self.gameHistoryTableView.reloadData()
            }
        }
    }
    

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.listener.remove()
        
        // Turn access back on
        Firestore.firestore().enableNetwork { (error) in
            // Do online things
            // ...
        }
    }
    
    // MARK: - Segues
    // Source Master-Detail project starter code.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueHistoryDetail" {
            if let /*indexPath*/ _ = gameHistoryTableView.indexPathForSelectedRow {
//                let game = games[indexPath.row].playerOneName
//                let game2 = games[indexPath.row].gameBoard
                
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
        Util.log("\(games.count)")
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
    
    
    // Allow Deletion
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Actually delete. Firestore takes care of caching deletes IF we are off line. Sweet.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete){
            let singeGameToDelete = games[indexPath.row]
            _ = Firestore.firestore().collection("history").document(singeGameToDelete.id).delete()
        }
    }
}

// MARK: - Table View code: Delegates
extension HistoryMasterViewController: UITableViewDelegate {
    
    // Here as a placeholder. All functions are evidently optional.

}

