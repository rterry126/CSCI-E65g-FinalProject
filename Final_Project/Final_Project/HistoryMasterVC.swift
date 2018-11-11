//
//  History_master.swift
//  Final_Project
//
//  Created by Robert Terry on 11/10/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import UIKit

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
    
    let tableSections = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
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
        return 5 // Placeholder for now
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
//        let menuItem = myRestaurantBill.item(at: indexPath).description
//        let itemQuantity = myRestaurantBill.item(at: indexPath).quantity
        
        
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
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //TODO: So delete from database and if successful then remove from table
            
//            let itemToDelete = myRestaurantBill.item(at: indexPath).description
//            let success = myRestaurantBill.removeAllItems(name: itemToDelete)
//            if success != 0{
//                itemOrderedTableView.deleteRows(at: [indexPath], with: .left)
                updateUI()
//                }
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
