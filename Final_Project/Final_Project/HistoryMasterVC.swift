//
//  History_master.swift
//  Final_Project
//
//  Created by Robert Terry on 11/10/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - https://code.tutsplus.com/tutorials/getting-started-with-cloud-firestore-for-ios--cms-30910

import UIKit
import Firebase

// This is mostly code from the restaurant bill table view controller modified for this use.

class GameHistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var dateTime: UILabel!
    @IBOutlet weak var playerOneName: UILabel!
    @IBOutlet weak var playerTwoName: UILabel!
    @IBOutlet weak var playerOneScore: UILabel!
    @IBOutlet weak var playerTwoScore: UILabel!
    
    
  
}


//MARK: -
class HistoryMasterViewController: UIViewController {
    
    private var documents: [DocumentSnapshot] = []
    public var game: [Game] = []
    private var listener : ListenerRegistration!
    
    //TODO:- Revisit fileprivate
    fileprivate func baseQuery() -> Query {
        return Firestore.firestore().collection("history_test").order(by: "created_at").limit(to: 10)
    }
    
    fileprivate var query: Query? {
        didSet {
            if let listener = listener {
                listener.remove()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.query = baseQuery()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.listener =  query?.addSnapshotListener { (documents, error) in
            guard let snapshot = documents else {
                print("Error fetching documents results: \(error!)")
                return
            }
            
            let results = snapshot.documents.map { (document) -> Game in
                if let game = Game(dictionary: document.data(), id: document.documentID) {
                    print("History \(game.id) => \(game.playerOneName )")
                    return game
                }
                else {
                    fatalError("Unable to initialize type \(Game.self) with dictionary \(document.data())")
                }
            }
            
            self.game = results
            self.documents = snapshot.documents
            self.gameHistoryTableView.reloadData()
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.listener.remove()
    }
    
    
    
    /******************************************/
    
    let tableSections = 1
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//
//    }
    
    //MARK: - Properties
    
    // LInk to history model here!!
    //var myMenu: MenuProtocol = RestaurantMenu()
    
    
    
    //MARK: - Methods
    
    func updateUI() {
        
        
    }
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var gameHistoryTableView: UITableView!
    
    
    // MARK: - Actions
    
 
       // itemOrderedTableView.reloadData()
    
}





// MARK: - Table View code: Datasource
extension HistoryMasterViewController: UITableViewDataSource {
    
    func numberOfSections(in gameHistoryTableView: UITableView) -> Int {
        return tableSections // 'tableSections' is a Created class constant
    }
    
    
    // Number of items on the bill, which will be number of rows in table view
    func tableView(_ gameHistoryTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Number of history items needed
        return game.count
    }
    
    
    
    // Actually populate the table, cell by cell
    func tableView(_ gameHistoryTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // The 'dequeue' code for custom cell includes an as?, in case it can't cast as the custom cell class.
        // A more robust implementation would be to fall back to a non-custom cell vice throwing an error.
        // Source cited for as?
        guard let cell = gameHistoryTableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as? GameHistoryTableViewCell  else {
            fatalError("Cannot create custom table view cell!")
        }
        
        //displaying values
        // Tried to pass in an IndexPath but
        
        //TODO: - Here is where we set the individual values for the cell: Date, Player Names, score, etc

        let item = game[indexPath.row]
        
        print("printing from dequeue cell \(item.playerOneName)")
        cell.playerOneName.text = item.playerOneName
        cell.playerOneScore.text = item.playerOneScore.description
        cell.playerTwoName.text = item.playerOneName
        cell.playerTwoScore.text = item.playerTwoScore.description


        // Customize its appearance according to our data model
        
        //TODO: - See if this is needed or is above enough
        
//        if let priceLookedUp = myMenu.lookupItem(name: menuItem) {
//            // Build 'Item' field
//            cell.itemOrderedLabel?.text = "\(menuItem)"
//            // Build Quantity text
//            cell.itemOrderedQuantityLabel?.text = "(\(itemQuantity) @\(priceLookedUp.price.centsToUSDollars))"
//            // Build 'price' field
//            cell.itemOrderedPriceLabel?.text = "\((itemQuantity * priceLookedUp.price).centsToUSDollars)"
//        }
        // Return it to iOS to render
        return cell
    }
    
    
    
    // Source cited
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//
//            //TODO: So delete from database and if successful then remove from table
//
////            let itemToDelete = myRestaurantBill.item(at: indexPath).description
////            let success = myRestaurantBill.removeAllItems(name: itemToDelete)
////            if success != 0{
////                itemOrderedTableView.deleteRows(at: [indexPath], with: .left)
//                updateUI()
////                }
//        }
//    }
    
    // Delete History
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete){
            let item = game[indexPath.row]
            _ = Firestore.firestore().collection("history_test").document(item.id).delete()
        }
        
    }
    
    
    //TODO: - Shouldn't need this as only one section
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return MenuCategory.categories[section]
//    }
}

// MARK: - Table View code: Delegate
extension HistoryMasterViewController: UITableViewDelegate {
    // Delegate functions all appear to be optional, and table currently works to spec without any functions here.
    
    
}
