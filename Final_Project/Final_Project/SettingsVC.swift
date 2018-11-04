//
//  SettingsVC.swift
//  Final_Project
//
//  Created by Robert Terry on 11/4/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - Enums for datasource - https://github.com/ianhirschfeld/EnumTableViewTutorial/blob/master/EnumTableViewTutorial/ViewController.swift
// Sources - quick refresher for making dynamic table views - https://swiftludus.org/how-to-create-dynamic-lists-of-items-with-uitableview/

import UIKit

class SettingsVC: UITableViewController {
    
    
    @IBOutlet weak var tableViewSettings: UITableView!
    
    let healthyFoods = ["Apple", "Orange", "Pear", "Grapefruit", "Potato", "Tomato", "Leek", "Tangerine"]
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return healthyFoods.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsItemCell", for: indexPath)
        cell.textLabel?.text = healthyFoods[indexPath.row]
        return cell
    }
    
    
    // Use this to segue to the setting view...
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(healthyFoods[indexPath.row])
    }
}
