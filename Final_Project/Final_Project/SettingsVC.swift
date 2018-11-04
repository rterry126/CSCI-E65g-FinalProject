//
//  SettingsVC.swift
//  Final_Project
//
//  Created by Robert Terry on 11/4/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - Enums for datasource - https://github.com/ianhirschfeld/EnumTableViewTutorial/blob/master/EnumTableViewTutorial/ViewController.swift
// Sources - quick refresher for making dynamic table views - https://swiftludus.org/how-to-create-dynamic-lists-of-items-with-uitableview/
// Source - counting occurances in array - https://stackoverflow.com/questions/30545518/how-to-count-occurrences-of-an-element-in-a-swift-array

import UIKit

class SettingsVC: UITableViewController {
    
    
    @IBOutlet weak var tableViewSettings: UITableView!
    
    enum TableSection: Int {
        case playerInfo = 0, boardSettings, total
    }
    
    let healthyFoods = ["Apple", "Orange", "Pear", "Grapefruit", "Potato", "Tomato", "Leek", "Tangerine"]
    
    let settingsItems = ["Player Names": TableSection.playerInfo, "Colors": .playerInfo, "Board Size": .boardSettings]
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableSection.total.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.filter{$0.value.rawValue == section}.count
//        return healthyFoods.count
        
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsItemCell", for: indexPath)
//        cell.textLabel?.text = settingsItems[indexPath.row]
        let items = Array(settingsItems.filter { $0.value.rawValue == indexPath.row }.keys)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    
    // Use this to segue to the setting view...
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print(setting[indexPath.row])
    }
}
