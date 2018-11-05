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
    
    override func viewDidLoad() {
        
        // Remove empty rows
        tableView.tableFooterView = UIView()
//        tableView.backgroundColor = UIColor.red
    }

}
