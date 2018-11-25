//
//  HistoryDetailVC.swift
//  Final_Project
//
//  Created by Robert Terry on 11/14/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import Foundation
import UIKit


class HistoryDetailVC: UIViewController {
    
    @IBOutlet weak var testLabel: UILabel!
    
    var username:String = ""
    // Stub/placeholer to build view
    let gameBoard = [["Player One","Empty","Empty","Player One","Empty"],
                     ["Empty","Player Two","Player One","Empty","Empty"],
                     ["Player One","Empty","Player Two","Empty","Empty"],
                     ["Empty","Empty","Player Two","Player One","Empty"],
                     ["Empty","Empty","Empty","Player Two","Empty"]]
    
    
        
        
    override func viewDidLoad() {
            super.viewDidLoad()
            print("Detail --> \(username)")
            print("\(gameBoard)")
            
            testLabel.text = username
        
    
    }
}
